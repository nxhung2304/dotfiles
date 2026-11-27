const fs = require("node:fs");
const path = require("node:path");
const { runCommand, runJsonCommand } = require("./command");
const { SPECS_RELATIVE_DIR } = require("./specs");
const { COLUMN } = require("./columns");
const { groupClaudeAgentsByWorktree } = require("./live-state");
const { findResumableSession } = require("./sessions");
const { findReusableSpecPane } = require("./story");

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
    `Branch ${branch}${origin} is already checked out in this worktree. Work on spec ${task.id} here: ` +
    "do not run implement-prepare and do not create or enter another worktree. " +
    `Invoke implement-code with ${task.id}, then run the quality-runner agent, ` +
    `then invoke implement-finalize with thread_ts null and base_branch ${startPoint}.`
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

function buildAutoRunPrompt(task, autoApproveSpec = false) {
  const autoApproveFlag = autoApproveSpec && !task.isApproved ? " auto-approve-spec=true" : "";
  return `/vibe-issue ${task.id} max-parallel=1${autoApproveFlag}`;
}

function buildCreateSpecPrompt(issueNumbers, repoSlug) {
  if (issueNumbers.length === 1) return `/github-issues-to-md ${issueNumbers[0]} ${repoSlug ?? ""}`.trim();
  const issueList = issueNumbers.map((number) => `#${number}`).join(", ");
  return `Invoke the github-issues-to-md skill once for each of these GitHub issues of ${repoSlug ?? "this repo"}, one after another: ${issueList}. Then list the spec folders you created.`;
}

function buildAgentNameForPane(paneId) {
  return `claude-${paneId.toLowerCase().replace(/:/g, "-")}`;
}

function ensureTaskCanRunAutomatically(task) {
  ensureTaskCanStart(task);
  if (task.specPath.endsWith("/issue.md")) {
    throw new BoardActionError(`Task ${task.id} là thư mục tài liệu, vibe-issue chỉ chạy task có file spec`, 409);
  }
}

async function startAutoRun({ repoRoot, task, autoApproveSpec }) {
  ensureRunningInsideHerdr();
  ensureTaskCanRunAutomatically(task);
  const created = await runJsonCommand("herdr", ["workspace", "create", "--cwd", repoRoot, "--label", `[AUTO] ${task.id}`, "--focus"]);
  const paneId = created.result.root_pane.pane_id;
  await runCommand("herdr", ["agent", "start", buildAgentNameForPane(paneId), "--kind", "claude", "--pane", paneId]);
  const prompt = buildAutoRunPrompt(task, autoApproveSpec);
  await sendPrompt(paneId, prompt);
  return { paneId, prompt, isPromptSent: true };
}

async function openRepoClaudeWithPrompt({ repoRoot, label, prompt }) {
  ensureRunningInsideHerdr();
  const created = await runJsonCommand("herdr", ["workspace", "create", "--cwd", repoRoot, "--label", label, "--focus"]);
  const paneId = created.result.root_pane.pane_id;
  await runCommand("herdr", ["agent", "start", buildAgentNameForPane(paneId), "--kind", "claude", "--pane", paneId]);
  await sendPrompt(paneId, prompt);
  return { paneId, prompt, isPromptSent: true };
}

async function startSpecCreation({ repoRoot, issueNumbers, repoSlug }) {
  const label = issueNumbers.length === 1 ? `[SPEC] #${issueNumbers[0]}` : `[SPEC] #${issueNumbers[0]} +${issueNumbers.length - 1}`;
  return openRepoClaudeWithPrompt({ repoRoot, label, prompt: buildCreateSpecPrompt(issueNumbers, repoSlug) });
}

function buildCreateStorySpecPrompt(storyTask) {
  return [
    `Create the local spec for the story task "${storyTask.title}" from specs/story.md, only for this task.`,
    `Use the generate-issues skill and save it as specs/issues/${storyTask.slug}/issue.md. Do not post anything to GitHub.`,
    "Ask me about anything unclear before writing.",
  ].join(" ");
}

async function startStorySpecCreation({ repoRoot, storyTask }) {
  return openRepoClaudeWithPrompt({ repoRoot, label: `[SPEC] ${storyTask.slug}`, prompt: buildCreateStorySpecPrompt(storyTask) });
}

function buildCreateIssuePrompt(specPath) {
  return [
    `Create a GitHub issue for the local spec ${specPath}, only for this file.`,
    "Follow the md-to-github-issues steps: pick the right gh account, check the repo, create missing labels, then gh issue create with the spec as the body.",
    "Before running gh issue create, show me the title, labels and body and wait for my OK.",
    'After it is created, write the issue number into the spec\'s "GitHub Issue:" line.',
    "If the spec is not Approved, stop and tell me instead.",
  ].join(" ");
}

async function findIdleSpecPane(slug) {
  if (!process.env.HERDR_ENV) return null;
  const [workspaceList, agentList] = await Promise.all([
    runJsonCommand("herdr", ["workspace", "list"]),
    runJsonCommand("herdr", ["agent", "list"]),
  ]);
  return findReusableSpecPane(workspaceList.result.workspaces, agentList.result.agents, slug);
}

async function startIssueCreation({ repoRoot, task }) {
  if (task.githubIssues.length > 0) throw new BoardActionError(`Task ${task.id} đã có issue GitHub`, 409);
  if (task.onlyInBranch) throw new BoardActionError(`Spec ${task.id} chỉ có trên branch ${task.onlyInBranch}, hãy merge về trước`, 409);
  const prompt = buildCreateIssuePrompt(task.specPath);
  const specPane = await findIdleSpecPane(task.id);
  if (!specPane) return openRepoClaudeWithPrompt({ repoRoot, label: `[ISSUE] ${task.id}`, prompt });
  await runCommand("herdr", ["workspace", "focus", specPane.workspaceId]);
  await sendPrompt(specPane.paneId, prompt);
  return { paneId: specPane.paneId, prompt, isPromptSent: true };
}

function buildAgentStartArgs(paneId, sessionId) {
  const baseArgs = ["agent", "start", buildAgentNameForPane(paneId), "--kind", "claude", "--pane", paneId];
  return sessionId ? [...baseArgs, "--", "--resume", sessionId] : baseArgs;
}

async function findShellPaneInWorktree(worktreePath) {
  const { result } = await runJsonCommand("herdr", ["pane", "list"]);
  const pane = result.panes.find((candidate) => candidate.cwd === worktreePath);
  return pane ?? null;
}

function buildUncommittedReviewPrompt(statusLines) {
  return [
    `Worktree này còn ${statusLines.length} file chưa commit, trong khi PR của task đã merge:`,
    ...statusLines.map((line) => `- ${line}`),
    "Xem từng file (git diff) rồi cho tôi biết file nào nên commit, stash hoặc bỏ. Đừng tự xoá hay revert, hỏi tôi trước.",
  ].join("\n");
}

async function readUncommittedStatusLines(worktreePath) {
  const output = await runCommand("git", ["status", "--short"], { cwd: worktreePath });
  return String(output ?? "").split("\n").filter(Boolean);
}

async function resumeTaskSession({ repoRoot, task, reviewUncommitted = false }) {
  ensureRunningInsideHerdr();
  if (!task.worktree || task.worktree.isMain) throw new BoardActionError(`Task ${task.id} chưa có worktree riêng`, 409);
  if (task.agent) throw new BoardActionError(`Task ${task.id} đã có phiên Claude`, 409);
  const session = await findResumableSession({ worktreePath: task.worktree.path, pullRequestNumber: task.pullRequest?.number ?? null });
  const existingPane = await findShellPaneInWorktree(task.worktree.path);
  let paneId = existingPane?.pane_id;
  if (existingPane) {
    await runCommand("herdr", ["workspace", "focus", existingPane.workspace_id]);
  } else {
    const label = `[WT] ${path.basename(task.worktree.path).replace(`${path.basename(repoRoot)}.`, "")}`;
    const created = await runJsonCommand("herdr", ["workspace", "create", "--cwd", task.worktree.path, "--label", label, "--focus"]);
    paneId = created.result.root_pane.pane_id;
  }
  await runCommand("herdr", buildAgentStartArgs(paneId, session?.sessionId ?? null));
  const resumed = { paneId, sessionId: session?.sessionId ?? null, reason: session?.reason ?? "new" };
  if (!reviewUncommitted) return resumed;
  const statusLines = await readUncommittedStatusLines(task.worktree.path);
  if (statusLines.length === 0) return { ...resumed, isPromptSent: false };
  const readyPaneId = await waitForClaudePane(task.worktree.path);
  if (!readyPaneId) return { ...resumed, isPromptSent: false };
  await sendPrompt(readyPaneId, buildUncommittedReviewPrompt(statusLines));
  return { ...resumed, isPromptSent: true };
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

function isWorktreeSafeToAutoCleanUp(task) {
  return (
    task.column === COLUMN.done &&
    task.pullRequest?.state === "MERGED" &&
    Boolean(task.worktree) &&
    !task.worktree.isMain &&
    !task.agent &&
    task.diffStats?.uncommittedFileCount === 0
  );
}

module.exports = {
  BoardActionError,
  isWorktreeSafeToAutoCleanUp,
  buildWorktreePath,
  buildStartPrompt,
  startTask,
  startAutoRun,
  startSpecCreation,
  startStorySpecCreation,
  startIssueCreation,
  buildCreateIssuePrompt,
  resumeTaskSession,
  buildAgentStartArgs,
  buildAutoRunPrompt,
  buildCreateSpecPrompt,
  buildUncommittedReviewPrompt,
  ensureTaskCanRunAutomatically,
  focusTask,
  cleanUpTaskWorktree,
};
