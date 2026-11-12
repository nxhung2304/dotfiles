const { runCommand } = require("./command");

const BASE_REF_CANDIDATES = ["origin/develop", "origin/main", "origin/master"];
const PREVIEW_SOURCE_LINES = "40";
const PREVIEW_LINE_COUNT = 2;
const PREVIEW_MAX_LENGTH = 160;
const PREVIEW_AGENT_STATUSES = ["blocked", "working"];
const ANSI_ESCAPE_PATTERN = /\x1b\[[0-9;?]*[A-Za-z]/g;
const TERMINAL_CHROME_PATTERN = /^[\s│|╭╮╰╯─━┃>❯·•*✻✶✳✢⏵⎿]*$|for shortcuts|esc to interrupt|bypass permissions|auto-accept/i;

async function findBaseRef(repoRoot) {
  for (const candidate of BASE_REF_CANDIDATES) {
    try {
      await runCommand("git", ["rev-parse", "--verify", "--quiet", candidate], { cwd: repoRoot });
      return candidate;
    } catch {
      continue;
    }
  }
  return null;
}

function parseShortStat(shortStat) {
  const readNumber = (pattern) => Number(shortStat.match(pattern)?.[1] ?? 0);
  return {
    filesChanged: readNumber(/(\d+) files? changed/),
    insertions: readNumber(/(\d+) insertions?/),
    deletions: readNumber(/(\d+) deletions?/),
  };
}

async function readDiffStats(worktreePath, baseRef) {
  const mergeBase = (await runCommand("git", ["merge-base", "HEAD", baseRef], { cwd: worktreePath })).trim();
  const [shortStat, statusOutput] = await Promise.all([
    runCommand("git", ["diff", "--shortstat", mergeBase], { cwd: worktreePath }),
    runCommand("git", ["status", "--porcelain"], { cwd: worktreePath }),
  ]);
  const uncommittedFileCount = statusOutput.split("\n").filter((line) => line.trim().length > 0).length;
  return { ...parseShortStat(shortStat), uncommittedFileCount };
}

function extractPreview(paneText) {
  const meaningfulLines = paneText
    .replace(ANSI_ESCAPE_PATTERN, "")
    .split("\n")
    .map((line) => line.replace(/^[\s│┃|]+|[\s│┃|]+$/g, ""))
    .filter((line) => /\p{L}/u.test(line) && !TERMINAL_CHROME_PATTERN.test(line));
  return meaningfulLines
    .slice(-PREVIEW_LINE_COUNT)
    .map((line) => (line.length > PREVIEW_MAX_LENGTH ? `${line.slice(0, PREVIEW_MAX_LENGTH)}…` : line));
}

async function readAgentPreview(paneId) {
  const paneText = await runCommand("herdr", ["pane", "read", paneId, "--source", "recent-unwrapped", "--lines", PREVIEW_SOURCE_LINES]);
  return extractPreview(paneText);
}

async function readWorktreeDetail(worktree, baseRef, agents) {
  const detail = { diffStats: null, previewLines: [] };
  try {
    if (baseRef) detail.diffStats = await readDiffStats(worktree.path, baseRef);
  } catch (error) {
    console.warn(`[board] diff stats for ${worktree.path}: ${error.message}`);
  }
  const previewAgent = agents.find((agent) => PREVIEW_AGENT_STATUSES.includes(agent.status));
  try {
    if (previewAgent) detail.previewLines = await readAgentPreview(previewAgent.paneId);
  } catch (error) {
    console.warn(`[board] preview for pane ${previewAgent.paneId}: ${error.message}`);
  }
  return detail;
}

async function readWorktreeDetails(repoRoot, worktrees, agentsByWorktreePath) {
  const baseRef = await findBaseRef(repoRoot);
  const taskWorktrees = worktrees.filter((worktree) => !worktree.isMain);
  const details = await Promise.all(
    taskWorktrees.map((worktree) => readWorktreeDetail(worktree, baseRef, agentsByWorktreePath.get(worktree.path) ?? [])),
  );
  return new Map(taskWorktrees.map((worktree, index) => [worktree.path, details[index]]));
}

module.exports = { parseShortStat, extractPreview, readWorktreeDetails };
