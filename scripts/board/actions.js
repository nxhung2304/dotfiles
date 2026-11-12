const fs = require("node:fs");
const path = require("node:path");
const { runCommand, runJsonCommand } = require("./command");
const { SPECS_RELATIVE_DIR } = require("./specs");
const { COLUMN } = require("./columns");
const { groupClaudeAgentsByWorktree } = require("./live-state");

const HERDR_SCRIPTS_DIR = path.resolve(__dirname, "..", "herdr");
const WORKTREE_WORKSPACE_SCRIPT = path.join(HERDR_SCRIPTS_DIR, "worktree-workspace");
const NOTIFY_AGENT_SCRIPT = path.join(HERDR_SCRIPTS_DIR, "notify-agent");
const BASE_BRANCH_CANDIDATES = ["develop", "main", "master"];
const STARTABLE_COLUMNS = [COLUMN.ready, COLUMN.todo];
const CLAUDE_READY_STATUSES = ["idle", "done"];
const CLAUDE_WAIT_TIMEOUT_MS = 30_000;
const CLAUDE_POLL_INTERVAL_MS = 1_000;

class BoardActionError extends Error {
  constructor(message, httpStatus) {
    super(message);
    this.httpStatus = httpStatus;
  }
}

async function buildBranchName(repoRoot, task, spec) {
  const userName = (await runCommand("git", ["config", "user.name"], { cwd: repoRoot })).trim();
  const userSlug = userName
    .normalize("NFD")
    .replace(/\p{Diacritic}/gu, "")
    .replace(/đ/gi, "d")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
  const issuePart = task.githubIssues.length > 0 ? `#${task.githubIssues[0]}-` : "";
  return `feature/${userSlug}-${issuePart}${spec.slug}`;
}

function buildWorktreePath(repoRoot, branch) {
  const branchSuffix = branch.replace(/#/g, "").replace(/\//g, "-");
  return path.join(path.dirname(repoRoot), `${path.basename(repoRoot)}.${branchSuffix}`);
}

async function findBaseBranch(repoRoot) {
  for (const candidate of BASE_BRANCH_CANDIDATES) {
    try {
      await runCommand("git", ["fetch", "origin", candidate], { cwd: repoRoot });
      return `origin/${candidate}`;
    } catch (error) {
      console.warn(`[board] base branch ${candidate} not usable: ${error.message}`);
    }
  }
  throw new BoardActionError("Không tìm thấy branch gốc (develop/main/master) trên origin", 500);
}

async function doesLocalBranchExist(repoRoot, branch) {
  try {
    await runCommand("git", ["rev-parse", "--verify", "--quiet", `refs/heads/${branch}`], { cwd: repoRoot });
    return true;
  } catch {
    return false;
  }
}

async function createWorktree(repoRoot, branch, worktreePath) {
  if (await doesLocalBranchExist(repoRoot, branch)) {
    await runCommand("git", ["worktree", "add", worktreePath, branch], { cwd: repoRoot });
    return { isNewBranch: false, startPoint: branch };
  }
  const baseBranch = await findBaseBranch(repoRoot);
  await runCommand("git", ["worktree", "add", "-b", branch, worktreePath, baseBranch], { cwd: repoRoot });
  return { isNewBranch: true, startPoint: baseBranch };
}

async function isTrackedByGit(repoRoot, relativePath) {
  try {
    await runCommand("git", ["ls-files", "--error-unmatch", relativePath], { cwd: repoRoot });
    return true;
  } catch {
    return false;
  }
}

async function copyUntrackedSpec(repoRoot, worktreePath, specId, specPath) {
  if (await isTrackedByGit(repoRoot, specPath)) return;
  const specFile = path.join(SPECS_RELATIVE_DIR, `${specId}.md`);
  for (const relativePath of [specFile, path.join(SPECS_RELATIVE_DIR, specId)]) {
    const sourcePath = path.join(repoRoot, relativePath);
    if (fs.existsSync(sourcePath)) fs.cpSync(sourcePath, path.join(worktreePath, relativePath), { recursive: true });
  }
}

function buildStartPrompt(task, branch, { isNewBranch, startPoint }) {
  if (task.specPath.endsWith("/issue.md")) {
    return (
      `Task docs: ${path.dirname(task.specPath)}/ (branch ${branch} is already checked out in this worktree). ` +
      "Read every file in that folder, tell me the current status and the next step, and wait for my go before changing code."
    );
  }
  if (!task.isApproved) {
    return task.githubIssues.length > 0 ? `/review-specs #${task.githubIssues[0]}` : `/review-specs ${task.id}`;
  }
  const origin = isNewBranch ? ` (new, from ${startPoint})` : " (existing branch)";
  return (
    `/implement-issue ${task.id} — Branch ${branch}${origin} is already checked out in this worktree. ` +
    "Skip the checkout, pull and branch-creation steps of implement-prepare and keep working on this branch."
  );
}

function wait(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

async function findReadyClaudePane(worktreePath) {
  const [paneList, agentList] = await Promise.all([
    runJsonCommand("herdr", ["pane", "list"]),
    runJsonCommand("herdr", ["agent", "list"]),
  ]);
  const agents = groupClaudeAgentsByWorktree([{ path: worktreePath }], paneList.result.panes, agentList.result.agents);
  const readyAgent = agents.get(worktreePath).find((agent) => CLAUDE_READY_STATUSES.includes(agent.status));
  return readyAgent ? readyAgent.paneId : null;
}

async function waitForClaudePane(worktreePath) {
  const deadline = Date.now() + CLAUDE_WAIT_TIMEOUT_MS;
  while (Date.now() < deadline) {
    try {
      const paneId = await findReadyClaudePane(worktreePath);
      if (paneId) return paneId;
    } catch (error) {
      console.warn(`[board] waiting for Claude in ${worktreePath}: ${error.message}`);
    }
    await wait(CLAUDE_POLL_INTERVAL_MS);
  }
  return null;
}

async function sendPrompt(paneId, prompt) {
  await runCommand("herdr", ["pane", "send-text", paneId, prompt]);
  await runCommand("herdr", ["pane", "send-keys", paneId, "enter"]);
}

function ensureRunningInsideHerdr() {
  if (!process.env.HERDR_ENV) {
    throw new BoardActionError("Board phải được mở từ một pane herdr thì mới mở được workspace cho task", 400);
  }
}

function ensureTaskCanStart(task) {
  if (!STARTABLE_COLUMNS.includes(task.column)) {
    throw new BoardActionError(`Task ${task.id} không ở Todo/Sẵn sàng`, 409);
  }
  if (task.onlyInBranch) {
    throw new BoardActionError(`Spec ${task.id} chỉ có trên branch ${task.onlyInBranch}, hãy merge về trước`, 409);
  }
  if (task.blockedBy.length > 0) {
    throw new BoardActionError(`Task ${task.id} còn bị chặn bởi: ${task.blockedBy.join(", ")}`, 409);
  }
}

async function openWorkspaceAndSendPrompt({ repoRoot, worktreePath, task, prompt }) {
  await copyUntrackedSpec(repoRoot, worktreePath, task.id, task.specPath);
  await runCommand(WORKTREE_WORKSPACE_SCRIPT, ["open", worktreePath]);
  const paneId = await waitForClaudePane(worktreePath);
  if (!paneId) throw new Error("Claude chưa sẵn sàng sau khi mở workspace");
  await sendPrompt(paneId, prompt);
}

async function startTask({ repoRoot, task, spec }) {
  ensureRunningInsideHerdr();
  ensureTaskCanStart(task);
  const branch = await buildBranchName(repoRoot, task, spec);
  const worktreePath = buildWorktreePath(repoRoot, branch);
  const branchOrigin = await createWorktree(repoRoot, branch, worktreePath);
  const prompt = buildStartPrompt(task, branch, branchOrigin);
  try {
    await openWorkspaceAndSendPrompt({ repoRoot, worktreePath, task, prompt });
    return { branch, worktreePath, isPromptSent: true, prompt };
  } catch (error) {
    console.error(`[board] worktree ${worktreePath} created but prompt not sent: ${error.message}`);
    return { branch, worktreePath, isPromptSent: false, prompt, warning: error.message };
  }
}

async function focusTask(task) {
  const paneId = task.agent?.paneId;
  if (!paneId) throw new BoardActionError(`Task ${task.id} chưa có phiên Claude nào trong herdr`, 409);
  await runCommand(NOTIFY_AGENT_SCRIPT, ["--focus", paneId]);
}

async function cleanUpTaskWorktree(repoRoot, task) {
  if (task.column !== COLUMN.done || !task.worktree || task.worktree.isMain) {
    throw new BoardActionError(`Task ${task.id} chưa xong hoặc không có worktree riêng`, 409);
  }
  const uncommittedFileCount = task.diffStats?.uncommittedFileCount ?? 0;
  if (uncommittedFileCount > 0) {
    throw new BoardActionError(`Worktree của ${task.id} còn ${uncommittedFileCount} file chưa commit`, 409);
  }
  if (process.env.HERDR_ENV) await runCommand(WORKTREE_WORKSPACE_SCRIPT, ["close", task.worktree.path]);
  await runCommand("git", ["worktree", "remove", task.worktree.path], { cwd: repoRoot });
}

module.exports = {
  BoardActionError,
  buildWorktreePath,
  buildStartPrompt,
  startTask,
  focusTask,
  cleanUpTaskWorktree,
};
