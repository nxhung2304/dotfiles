const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");
const { loadSpecs } = require("./specs");
const { buildBoard } = require("./columns");
const { createLiveStateReader } = require("./live-state");
const { readGithubWebUrl } = require("./repo-url");
const { BoardActionError, startTask, focusTask, closeTaskWorkspace } = require("./actions");

const HOST = "127.0.0.1";
const DEFAULT_PORT = 4777;
const MAX_REQUEST_BODY_BYTES = 10_000;
const PAGE_PATH = path.join(__dirname, "index.html");
const ALLOWED_HOSTNAMES = ["127.0.0.1", "localhost"];

const repoRoot = process.argv[2] ?? process.cwd();
const port = Number.parseInt(process.env.BOARD_PORT ?? "", 10) || DEFAULT_PORT;
const readLiveState = createLiveStateReader(repoRoot);
const startingTaskIds = new Set();
const githubWebUrlPromise = readGithubWebUrl(repoRoot);

async function readBoardState() {
  const specs = loadSpecs(repoRoot);
  const liveState = await readLiveState();
  return { specs, tasks: buildBoard(specs, liveState), warnings: liveState.warnings };
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

function readJsonBody(request) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    let receivedBytes = 0;
    request.on("data", (chunk) => {
      receivedBytes += chunk.length;
      if (receivedBytes > MAX_REQUEST_BODY_BYTES) {
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
  const { specs, tasks } = await readBoardState();
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

const ACTION_HANDLERS = {
  "/api/start": handleStart,
  "/api/focus": async (taskId) => focusTask((await findTaskContext(taskId)).task),
  "/api/close-workspace": async (taskId) => closeTaskWorkspace((await findTaskContext(taskId)).task),
};

async function handleAction(request, response, actionHandler) {
  if (!(request.headers["content-type"] ?? "").startsWith("application/json")) {
    throw new BoardActionError("Cần Content-Type application/json", 415);
  }
  const { taskId } = await readJsonBody(request);
  if (typeof taskId !== "string") throw new BoardActionError("Thiếu taskId", 400);
  sendJson(response, 200, (await actionHandler(taskId)) ?? { isOk: true });
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
    const { tasks, warnings } = await readBoardState();
    const githubWebUrl = await githubWebUrlPromise;
    sendJson(response, 200, { repoName: path.basename(repoRoot), githubWebUrl, tasks, warnings });
    return;
  }
  const actionHandler = ACTION_HANDLERS[pathname];
  if (request.method === "POST" && actionHandler) {
    await handleAction(request, response, actionHandler);
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
  console.log(`[board] ${path.basename(repoRoot)} → http://${HOST}:${port}`);
});
