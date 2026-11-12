const { runCommand, runJsonCommand } = require("./command");
const { readWorktreeDetails } = require("./worktree-details");

const HERDR_REFRESH_MS = 3_000;
const PULL_REQUEST_REFRESH_MS = 60_000;
const PULL_REQUEST_LIMIT = "200";
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

function createCachedReader(readFresh, refreshMs) {
  let cachedResult = null;
  let cachedAt = 0;
  return async () => {
    if (cachedResult && Date.now() - cachedAt < refreshMs) return cachedResult;
    cachedResult = await readFresh();
    cachedAt = Date.now();
    return cachedResult;
  };
}

async function readHerdrSnapshot() {
  try {
    const [paneList, agentList] = await Promise.all([
      runJsonCommand("herdr", ["pane", "list"]),
      runJsonCommand("herdr", ["agent", "list"]),
    ]);
    return { isAvailable: true, panes: paneList.result.panes, agents: agentList.result.agents };
  } catch (error) {
    return { isAvailable: false, error: error.message, panes: [], agents: [] };
  }
}

function createOpenIssueReader(repoRoot) {
  return async () => {
    try {
      const openIssues = await runJsonCommand(
        "gh",
        ["issue", "list", "--state", "open", "--limit", PULL_REQUEST_LIMIT, "--json", "number,title,url"],
        { cwd: repoRoot },
      );
      return { isAvailable: true, openIssues };
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
      return { isAvailable: true, pullRequests: pullRequests.map(summarizePullRequest) };
    } catch (error) {
      return { isAvailable: false, error: error.message, pullRequests: [] };
    }
  };
}

function createLiveStateReader(repoRoot) {
  const readHerdr = createCachedReader(readHerdrSnapshot, HERDR_REFRESH_MS);
  const readPullRequests = createCachedReader(createPullRequestReader(repoRoot), PULL_REQUEST_REFRESH_MS);
  const readOpenIssues = createCachedReader(createOpenIssueReader(repoRoot), PULL_REQUEST_REFRESH_MS);

  return async () => {
    const [worktreeOutput, herdr, pullRequestState, openIssueState] = await Promise.all([
      runCommand("git", ["worktree", "list", "--porcelain"], { cwd: repoRoot }),
      readHerdr(),
      readPullRequests(),
      readOpenIssues(),
    ]);
    const worktrees = parseWorktreeList(worktreeOutput);
    const agentsByWorktreePath = groupClaudeAgentsByWorktree(worktrees, herdr.panes, herdr.agents);
    return {
      worktrees,
      agentsByWorktreePath,
      worktreeDetailsByPath: await readWorktreeDetails(repoRoot, worktrees, agentsByWorktreePath),
      pullRequests: pullRequestState.pullRequests,
      openIssues: openIssueState.openIssues,
      warnings: [herdr.error, pullRequestState.error, openIssueState.error].filter(Boolean),
    };
  };
}

module.exports = { parseWorktreeList, groupClaudeAgentsByWorktree, summarizeChecks, createLiveStateReader };
