const { runCommand, runJsonCommand } = require("./command");

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

function createPullRequestReader(repoRoot) {
  return async () => {
    try {
      const pullRequests = await runJsonCommand(
        "gh",
        ["pr", "list", "--state", "all", "--limit", PULL_REQUEST_LIMIT, "--json", "number,state,headRefName,url"],
        { cwd: repoRoot },
      );
      return { isAvailable: true, pullRequests };
    } catch (error) {
      return { isAvailable: false, error: error.message, pullRequests: [] };
    }
  };
}

function createLiveStateReader(repoRoot) {
  const readHerdr = createCachedReader(readHerdrSnapshot, HERDR_REFRESH_MS);
  const readPullRequests = createCachedReader(createPullRequestReader(repoRoot), PULL_REQUEST_REFRESH_MS);

  return async () => {
    const [worktreeOutput, herdr, pullRequestState] = await Promise.all([
      runCommand("git", ["worktree", "list", "--porcelain"], { cwd: repoRoot }),
      readHerdr(),
      readPullRequests(),
    ]);
    const worktrees = parseWorktreeList(worktreeOutput);
    return {
      worktrees,
      agentsByWorktreePath: groupClaudeAgentsByWorktree(worktrees, herdr.panes, herdr.agents),
      pullRequests: pullRequestState.pullRequests,
      warnings: [herdr.error, pullRequestState.error].filter(Boolean),
    };
  };
}

module.exports = { parseWorktreeList, groupClaudeAgentsByWorktree, createLiveStateReader };
