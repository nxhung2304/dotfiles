const http = require("node:http");
const os = require("node:os");
const { execFileSync } = require("node:child_process");
const fs = require("node:fs");
const path = require("node:path");
const { loadSpecs } = require("./specs");
const { buildBoard, findIssuesWithoutSpec, findUnlinkedWorktrees } = require("./columns");
const { createLiveStateReader } = require("./live-state");
const { readGithubWebUrl } = require("./repo-url");
const { readSpecDetail, writeSpecFile, readIssueDetail } = require("./details");
const { BoardActionError, startTask, startAutoRun, focusTask, cleanUpTaskWorktree } = require("./actions");

const IS_LAN_MODE = process.env.BOARD_LAN === "1";
const HOST = IS_LAN_MODE ? "0.0.0.0" : "127.0.0.1";
const DEFAULT_PORT = 4777;
const MAX_REQUEST_BODY_BYTES = 10_000;
const MAX_SPEC_BODY_BYTES = 1_000_000;
const SPEC_SAVE_PATH = "/api/spec-save";
const PAGE_PATH = path.join(__dirname, "index.html");
function listLanAddresses() {
  return Object.values(os.networkInterfaces())
    .flat()
    .filter((address) => address && address.family === "IPv4" && !address.internal)
    .map((address) => address.address);
}

const ALLOWED_HOSTNAMES = ["127.0.0.1", "localhost", ...(IS_LAN_MODE ? listLanAddresses() : [])];

const repoRoot = process.argv[2] ?? process.cwd();
const port = Number.parseInt(process.env.BOARD_PORT ?? "", 10) || DEFAULT_PORT;
const readLiveState = createLiveStateReader(repoRoot);
const startingTaskIds = new Set();

function readMainRepoName() {
  try {
    const gitCommonDir = execFileSync("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], { cwd: repoRoot, encoding: "utf8" }).trim();
    return path.basename(path.dirname(gitCommonDir));
  } catch {
    return path.basename(repoRoot);
  }
}

const mainRepoName = readMainRepoName();
const githubWebUrlPromise = readGithubWebUrl(repoRoot);

function loadSpecsOnlyInWorktrees(worktrees, mainSpecIds) {
  const seenSpecIds = new Set(mainSpecIds);
  const extraSpecs = [];
  for (const worktree of worktrees.filter((candidate) => !candidate.isMain)) {
    for (const spec of loadSpecs(worktree.path)) {
      if (seenSpecIds.has(spec.id)) continue;
      seenSpecIds.add(spec.id);
      extraSpecs.push({ ...spec, onlyInBranch: worktree.branch ?? worktree.path, sourceRoot: worktree.path });
    }
  }
  return extraSpecs;
}

async function readBoardState() {
  const liveState = await readLiveState();
  const mainSpecs = loadSpecs(repoRoot);
  const specs = [...mainSpecs, ...loadSpecsOnlyInWorktrees(liveState.worktrees, mainSpecs.map((spec) => spec.id))];
  return {
    specs,
    tasks: buildBoard(specs, liveState),
    issuesWithoutSpec: findIssuesWithoutSpec(specs, liveState.openIssues),
    unlinkedWorktrees: findUnlinkedWorktrees(specs, liveState),
    warnings: liveState.warnings,
  };
}

function sendJson(response, httpStatus, body) {
  response.writeHead(httpStatus, { "Content-Type": "application/json; charset=utf-8" });
  response.end(JSON.stringify(body));
}

function isTrustedRequest(request) {
  const hostname = (request.headers.host ?? "").split(":")[0];
  if (!ALLOWED_HOSTNAMES.includes(hostname)) return false;
  const origin = request.headers.origin;
  if (!origin) return true;
  try {
    return ALLOWED_HOSTNAMES.includes(new URL(origin).hostname);
  } catch {
    return false;
  }
}

function readJsonBody(request, maxBytes = MAX_REQUEST_BODY_BYTES) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let receivedBytes = 0;
    request.on("data", (chunk) => {
      receivedBytes += chunk.length;
      if (receivedBytes > maxBytes) {
        reject(new BoardActionError("Request quá lớn", 413));
        request.destroy();
        return;
      }
      chunks.push(chunk);
    });
    request.on("end", () => {
      try {
        resolve(JSON.parse(Buffer.concat(chunks).toString("utf8") || "{}"));
      } catch {
        reject(new BoardActionError("Body không phải JSON", 400));
      }
    });
    request.on("error", reject);
  });
}

async function findTaskContext(taskId) {
  const { specs, tasks, unlinkedWorktrees } = await readBoardState();
  const unlinkedWorktree = unlinkedWorktrees.find((worktree) => `worktree:${worktree.path}` === taskId);
  if (unlinkedWorktree) return { task: { id: taskId, ...unlinkedWorktree }, spec: null };
  const task = tasks.find((candidate) => candidate.id === taskId);
  if (!task) throw new BoardActionError(`Không tìm thấy task ${taskId}`, 404);
  return { task, spec: specs.find((candidate) => candidate.id === taskId) };
}

async function handleStart(taskId) {
  if (startingTaskIds.has(taskId)) throw new BoardActionError(`Task ${taskId} đang được khởi động`, 409);
  startingTaskIds.add(taskId);
  try {
    const { task, spec } = await findTaskContext(taskId);
    return await startTask({ repoRoot, task, spec });
  } finally {
    startingTaskIds.delete(taskId);
  }
}

async function handleStartAuto(taskId, { autoApproveSpec }) {
  if (startingTaskIds.has(taskId)) throw new BoardActionError(`Task ${taskId} đang được khởi động`, 409);
  startingTaskIds.add(taskId);
  try {
    const { task } = await findTaskContext(taskId);
    return await startAutoRun({ repoRoot, task, autoApproveSpec: autoApproveSpec === true });
  } finally {
    startingTaskIds.delete(taskId);
  }
}

const ACTION_HANDLERS = {
  "/api/start": handleStart,
  "/api/start-auto": handleStartAuto,
  "/api/focus": async (taskId) => focusTask((await findTaskContext(taskId)).task),
  [SPEC_SAVE_PATH]: handleSpecSave,
  "/api/clean-up": async (taskId) => cleanUpTaskWorktree(repoRoot, (await findTaskContext(taskId)).task),
};

async function handleSpecSave(specId, { fileName, content, baseModifiedMs }) {
  if (IS_LAN_MODE) throw new BoardActionError("Không sửa spec khi board chạy ở chế độ --lan", 403);
  const { specs } = await readBoardState();
  const spec = specs.find((candidate) => candidate.id === specId);
  if (!spec) throw new BoardActionError(`Không tìm thấy spec ${specId}`, 404);
  return writeSpecFile(repoRoot, spec, { fileName, content, baseModifiedMs });
}

async function handleDetail(searchParams) {
  if (searchParams.has("issue")) return readIssueDetail(repoRoot, Number(searchParams.get("issue")));
  const specId = searchParams.get("spec");
  const { specs } = await readBoardState();
  const spec = specs.find((candidate) => candidate.id === specId);
  if (!spec) throw new BoardActionError(`Không tìm thấy spec ${specId}`, 404);
  const detail = readSpecDetail(repoRoot, spec, searchParams.get("file"));
  return { ...detail, canEdit: detail.canEdit && !IS_LAN_MODE };
}

async function handleAction(request, response, actionHandler, maxBodyBytes) {
  if (!(request.headers["content-type"] ?? "").startsWith("application/json")) {
    throw new BoardActionError("Cần Content-Type application/json", 415);
  }
  const requestBody = await readJsonBody(request, maxBodyBytes);
  if (typeof requestBody.taskId !== "string") throw new BoardActionError("Thiếu taskId", 400);
  sendJson(response, 200, (await actionHandler(requestBody.taskId, requestBody)) ?? { isOk: true });
}

async function routeRequest(request, response) {
  const { pathname } = new URL(request.url, `http://${HOST}`);
  if (request.method === "GET" && pathname === "/") {
    const page = await fs.promises.readFile(PAGE_PATH);
    response.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
    response.end(page);
    return;
  }
  if (request.method === "GET" && pathname === "/api/board") {
    const { tasks, issuesWithoutSpec, unlinkedWorktrees, warnings } = await readBoardState();
    const githubWebUrl = await githubWebUrlPromise;
    sendJson(response, 200, { repoName: mainRepoName, githubWebUrl, tasks, issuesWithoutSpec, unlinkedWorktrees, warnings });
    return;
  }
  if (request.method === "GET" && pathname === "/api/detail") {
    sendJson(response, 200, await handleDetail(new URL(request.url, `http://${HOST}`).searchParams));
    return;
  }
  const actionHandler = ACTION_HANDLERS[pathname];
  if (request.method === "POST" && actionHandler) {
    await handleAction(request, response, actionHandler, pathname === SPEC_SAVE_PATH ? MAX_SPEC_BODY_BYTES : undefined);
    return;
  }
  sendJson(response, 404, { error: "Not found" });
}

const server = http.createServer(async (request, response) => {
  if (!isTrustedRequest(request)) {
    sendJson(response, 403, { error: "Forbidden" });
    return;
  }
  try {
    await routeRequest(request, response);
  } catch (error) {
    console.error(`[board] ${request.method} ${request.url}: ${error.message}`);
    sendJson(response, error.httpStatus ?? 500, { error: error.message });
  }
});

server.listen(port, HOST, () => {
  const addresses = IS_LAN_MODE ? ["127.0.0.1", ...listLanAddresses()] : [HOST];
  console.log(`[board] ${path.basename(repoRoot)} → ${addresses.map((address) => `http://${address}:${port}`).join("  ")}`);
});
