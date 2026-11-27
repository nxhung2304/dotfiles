const { runCommand, runJsonCommand } = require("./command");
const { readWorktreeDetails, readAgentPreview } = require("./worktree-details");
const { readRunFiles, findActiveAutoRuns } = require("./auto-runs");

const HERDR_REFRESH_MS = 3_000;
const PULL_REQUEST_REFRESH_MS = 60_000;
const FAILED_READ_RETRY_MS = 10_000;
const GITHUB_LIST_LIMIT = 1000;
const PULL_REQUEST_LIMIT = String(GITHUB_LIST_LIMIT);
const CLAUDE_AGENT_LABEL = "claude";

function parseWorktreeList(porcelainOutput) {
  return porcelainOutput
    .split("\n\n")
    .map((block) => block.trim())
    .filter((block) => block.length > 0)
    .map((block, index) => ({
      path: block.match(/^worktree (.+)$/m)?.[1] ?? "",
      branch: block.match(/^branch refs\/heads\/(.+)$/m)?.[1] ?? null,
      isMain: index === 0,
    }));
}

function isPathInside(childPath, parentPath) {
  return childPath === parentPath || childPath.startsWith(`${parentPath}/`);
}

function groupClaudeAgentsByWorktree(worktrees, panes, agents) {
  const agentsByWorktreePath = new Map();
  for (const worktree of worktrees) {
    const paneIds = new Set(
      panes.filter((pane) => isPathInside(pane.cwd ?? "", worktree.path)).map((pane) => pane.pane_id),
    );
    const worktreeAgents = agents
      .filter((agent) => agent.agent === CLAUDE_AGENT_LABEL && paneIds.has(agent.pane_id))
      .map((agent) => ({ paneId: agent.pane_id, status: agent.agent_status }));
    agentsByWorktreePath.set(worktree.path, worktreeAgents);
  }
  return agentsByWorktreePath;
}

async function addAutoRunPreviews(autoRunBySpecId) {
  for (const autoRun of autoRunBySpecId.values()) {
    if (!["blocked", "working"].includes(autoRun.agentStatus)) continue;
    try {
      autoRun.previewLines = await readAgentPreview(autoRun.paneId, autoRun.agentStatus);
    } catch (error) {
      console.warn(`[board] preview for pane ${autoRun.paneId}: ${error.message}`);
    }
  }
  return autoRunBySpecId;
}

function createCachedReader(readFresh, refreshMs, { keepLastGood = false } = {}) {
  let cachedResult = null;
  let cachedAt = 0;
  let lastGoodResult = null;
  return async () => {
    const needsEarlyRetry = cachedResult && (cachedResult.isAvailable === false || cachedResult.isStale);
    if (cachedResult && Date.now() - cachedAt < (needsEarlyRetry ? FAILED_READ_RETRY_MS : refreshMs)) return cachedResult;
    const freshResult = await readFresh();
    if (freshResult.isAvailable !== false) lastGoodResult = freshResult;
    const shouldReuseLastGood = freshResult.isAvailable === false && keepLastGood && lastGoodResult;
    cachedResult = shouldReuseLastGood
      ? { ...lastGoodResult, isStale: true, error: `${freshResult.error} (đang hiện dữ liệu của lần đọc trước)` }
      : freshResult;
    cachedAt = Date.now();
    return cachedResult;
  };
}

async function readHerdrSnapshot() {
  try {
    const [paneList, agentList, workspaceList] = await Promise.all([
      runJsonCommand("herdr", ["pane", "list"]),
      runJsonCommand("herdr", ["agent", "list"]),
      runJsonCommand("herdr", ["workspace", "list"]),
    ]);
    return { isAvailable: true, panes: paneList.result.panes, agents: agentList.result.agents, workspaces: workspaceList.result.workspaces };
  } catch (error) {
    return { isAvailable: false, error: error.message, panes: [], agents: [], workspaces: [] };
  }
}

function buildTruncationNotice(items, listName) {
  return items.length >= GITHUB_LIST_LIMIT ? `Danh sách ${listName} từ GitHub bị cắt ở ${GITHUB_LIST_LIMIT} mục, task cũ có thể hiện sai trạng thái` : null;
}

function createOpenIssueReader(repoRoot) {
  return async () => {
    try {
      const openIssues = await runJsonCommand(
        "gh",
        ["issue", "list", "--state", "open", "--limit", PULL_REQUEST_LIMIT, "--json", "number,title,url"],
        { cwd: repoRoot },
      );
      return { isAvailable: true, openIssues, notice: buildTruncationNotice(openIssues, "issue đang mở") };
    } catch (error) {
      return { isAvailable: false, error: error.message, openIssues: [] };
    }
  };
}

const FAILED_CHECK_RESULTS = ["FAILURE", "ERROR", "CANCELLED", "TIMED_OUT", "ACTION_REQUIRED", "STARTUP_FAILURE"];
const PASSED_CHECK_RESULTS = ["SUCCESS", "NEUTRAL", "SKIPPED"];

function summarizeChecks(statusCheckRollup) {
  if (!Array.isArray(statusCheckRollup) || statusCheckRollup.length === 0) return null;
  const results = statusCheckRollup.map((check) => check.conclusion || check.state || check.status || "");
  if (results.some((result) => FAILED_CHECK_RESULTS.includes(result))) return "failing";
  if (results.every((result) => PASSED_CHECK_RESULTS.includes(result))) return "passing";
  return "pending";
}

function summarizePullRequest({ statusCheckRollup, reviewDecision, ...pullRequest }) {
  return { ...pullRequest, checks: summarizeChecks(statusCheckRollup), reviewDecision: reviewDecision || null };
}

function createPullRequestReader(repoRoot) {
  return async () => {
    try {
      const pullRequests = await runJsonCommand(
        "gh",
        ["pr", "list", "--state", "all", "--limit", PULL_REQUEST_LIMIT, "--json", "number,state,isDraft,headRefName,url,mergedAt,reviewDecision,statusCheckRollup"],
        { cwd: repoRoot },
      );
      return { isAvailable: true, pullRequests: pullRequests.map(summarizePullRequest), notice: buildTruncationNotice(pullRequests, "PR") };
    } catch (error) {
      return { isAvailable: false, error: error.message, pullRequests: [] };
    }
  };
}

function createClosedIssueReader(repoRoot) {
  return async () => {
    try {
      const closedIssues = await runJsonCommand(
        "gh",
        ["issue", "list", "--state", "closed", "--limit", PULL_REQUEST_LIMIT, "--json", "number"],
        { cwd: repoRoot },
      );
      return { isAvailable: true, closedIssueNumbers: closedIssues.map((issue) => issue.number), notice: buildTruncationNotice(closedIssues, "issue đã đóng") };
    } catch (error) {
      return { isAvailable: false, error: error.message, closedIssueNumbers: [] };
    }
  };
}

function createLiveStateReader(repoRoot) {
  const readHerdr = createCachedReader(readHerdrSnapshot, HERDR_REFRESH_MS);
  const readPullRequests = createCachedReader(createPullRequestReader(repoRoot), PULL_REQUEST_REFRESH_MS, { keepLastGood: true });
  const readOpenIssues = createCachedReader(createOpenIssueReader(repoRoot), PULL_REQUEST_REFRESH_MS, { keepLastGood: true });
  const readClosedIssues = createCachedReader(createClosedIssueReader(repoRoot), PULL_REQUEST_REFRESH_MS, { keepLastGood: true });

  let latestWorktreeDetailInput = null;
  const readWorktreeDetailsCached = createCachedReader(
    async () => ({ detailsByPath: await readWorktreeDetails(...latestWorktreeDetailInput) }),
    HERDR_REFRESH_MS,
  );

  return async () => {
    const [worktreeOutput, herdr, pullRequestState, openIssueState, closedIssueState] = await Promise.all([
      runCommand("git", ["worktree", "list", "--porcelain"], { cwd: repoRoot }),
      readHerdr(),
      readPullRequests(),
      readOpenIssues(),
      readClosedIssues(),
    ]);
    const worktrees = parseWorktreeList(worktreeOutput);
    const agentsByWorktreePath = groupClaudeAgentsByWorktree(worktrees, herdr.panes, herdr.agents);
    const autoRunBySpecId = await addAutoRunPreviews(findActiveAutoRuns(readRunFiles(), herdr.workspaces, herdr.panes, herdr.agents));
    latestWorktreeDetailInput = [repoRoot, worktrees, agentsByWorktreePath];
    const { detailsByPath } = await readWorktreeDetailsCached();
    return {
      isHerdrAvailable: herdr.isAvailable !== false,
      worktrees,
      agentsByWorktreePath,
      herdrWorkspaces: herdr.workspaces,
      herdrAgents: herdr.agents,
      autoRunBySpecId,
      worktreeDetailsByPath: detailsByPath,
      pullRequests: pullRequestState.pullRequests,
      openIssues: openIssueState.openIssues,
      closedIssueNumbers: closedIssueState.closedIssueNumbers,
      warnings: [herdr, pullRequestState, openIssueState, closedIssueState].flatMap((state) => [state.error, state.notice]).filter(Boolean),
    };
  };
}

module.exports = { createCachedReader, parseWorktreeList, groupClaudeAgentsByWorktree, summarizeChecks, createLiveStateReader };
