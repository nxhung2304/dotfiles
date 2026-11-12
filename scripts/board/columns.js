const { resolveDependencies, PRIORITY_LEVELS } = require("./specs");

const COLUMN = {
  ready: "ready",
  todo: "todo",
  inProgress: "inProgress",
  needsYou: "needsYou",
  review: "review",
  done: "done",
};

const AGENT_STATUS_RANK = { blocked: 0, working: 1, done: 2, idle: 3 };
const PULL_REQUEST_STATE_RANK = { OPEN: 0, MERGED: 1 };
const LOWEST_RANK = 9;

function findSpecIdForBranch(branch, specs) {
  if (!branch) return null;
  const issueMatch = branch.match(/#(\d+)(?:-|$)/);
  if (issueMatch) {
    const specByIssue = specs.find((spec) => spec.githubIssues.includes(Number(issueMatch[1])));
    if (specByIssue) return specByIssue.id;
  }
  const specBySlug = specs.find(
    (spec) => branch === spec.slug || branch.endsWith(`-${spec.slug}`) || branch.endsWith(`/${spec.slug}`),
  );
  return specBySlug ? specBySlug.id : null;
}

function pickMostUrgentAgent(agents) {
  return [...agents].sort(
    (first, second) => (AGENT_STATUS_RANK[first.status] ?? LOWEST_RANK) - (AGENT_STATUS_RANK[second.status] ?? LOWEST_RANK),
  )[0] ?? null;
}

function rankPullRequest(pullRequest) {
  return PULL_REQUEST_STATE_RANK[pullRequest.state] ?? LOWEST_RANK;
}

function indexLiveStateBySpec(liveState, specs) {
  const worktreeBySpecId = new Map();
  for (const worktree of liveState.worktrees) {
    const specId = findSpecIdForBranch(worktree.branch, specs);
    if (specId && !worktreeBySpecId.has(specId)) worktreeBySpecId.set(specId, worktree);
  }
  const pullRequestBySpecId = new Map();
  for (const pullRequest of liveState.pullRequests) {
    const specId = findSpecIdForBranch(pullRequest.headRefName, specs);
    const existing = pullRequestBySpecId.get(specId);
    if (specId && (!existing || rankPullRequest(pullRequest) < rankPullRequest(existing))) {
      pullRequestBySpecId.set(specId, pullRequest);
    }
  }
  return { worktreeBySpecId, pullRequestBySpecId };
}

function isSpecDone(spec, pullRequest) {
  return spec.isMarkedDone || pullRequest?.state === "MERGED";
}

function deriveColumn({ isDone, pullRequest, worktree, agent, hasOpenDependencies }) {
  if (isDone) return COLUMN.done;
  if (worktree && agent?.status === "blocked") return COLUMN.needsYou;
  if (pullRequest?.state === "OPEN") return COLUMN.review;
  if (worktree) return COLUMN.inProgress;
  return hasOpenDependencies ? COLUMN.todo : COLUMN.ready;
}

function compareTasks(first, second) {
  const priorityOrder = PRIORITY_LEVELS.indexOf(first.priority) - PRIORITY_LEVELS.indexOf(second.priority);
  return priorityOrder !== 0 ? priorityOrder : first.id.localeCompare(second.id);
}

function buildTask(spec, { specs, liveState, worktreeBySpecId, pullRequestBySpecId, doneSpecIds }) {
  const { dependsOn, unresolvedDependencies } = resolveDependencies(spec, specs);
  const blockedBy = dependsOn.filter((specId) => !doneSpecIds.has(specId));
  const worktree = worktreeBySpecId.get(spec.id) ?? null;
  const pullRequest = pullRequestBySpecId.get(spec.id) ?? null;
  const agent = worktree ? pickMostUrgentAgent(liveState.agentsByWorktreePath.get(worktree.path) ?? []) : null;
  const column = deriveColumn({
    isDone: doneSpecIds.has(spec.id),
    pullRequest,
    worktree,
    agent,
    hasOpenDependencies: blockedBy.length > 0 || unresolvedDependencies.length > 0,
  });
  const { id, number, title, priority, githubIssues, isApproved } = spec;
  return {
    ...{ id, number, title, priority, githubIssues, isApproved },
    ...{ dependsOn, blockedBy, unresolvedDependencies, column, worktree, agent, pullRequest },
  };
}

function buildBoard(specs, liveState) {
  const { worktreeBySpecId, pullRequestBySpecId } = indexLiveStateBySpec(liveState, specs);
  const doneSpecIds = new Set(
    specs.filter((spec) => isSpecDone(spec, pullRequestBySpecId.get(spec.id))).map((spec) => spec.id),
  );

  const context = { specs, liveState, worktreeBySpecId, pullRequestBySpecId, doneSpecIds };
  return specs.map((spec) => buildTask(spec, context)).sort(compareTasks);
}

module.exports = { COLUMN, findSpecIdForBranch, deriveColumn, buildBoard };
