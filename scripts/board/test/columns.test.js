const test = require("node:test");
const assert = require("node:assert/strict");
const { parseSpec } = require("../specs");
const { COLUMN, deriveColumn, buildBoard, findSpecIdForBranch } = require("../columns");

function buildSpec(fileName, { issue, dependsOn = "—", pr = "Todo", priority = "P2" }) {
  const content = [
    "## **Status:**",
    "- Review: Approved",
    `- PR: ${pr}`,
    "## Metadata",
    `- **Title:** ${fileName}`,
    `- **GitHub Issue:** #${issue}`,
    `- **Depends on:** ${dependsOn}`,
    `- **Priority:** ${priority}`,
    "---",
  ].join("\n");
  return parseSpec(fileName, content);
}

const specs = [
  buildSpec("001-base.md", { issue: 1, pr: "Merged" }),
  buildSpec("002-next.md", { issue: 2, dependsOn: "001-base" }),
  buildSpec("003-blocked.md", { issue: 3, dependsOn: "002-next" }),
  buildSpec("004-working.md", { issue: 4 }),
  buildSpec("005-asking.md", { issue: 5 }),
  buildSpec("006-reviewing.md", { issue: 6 }),
  buildSpec("007-urgent.md", { issue: 7, priority: "P1" }),
];

const liveState = {
  worktrees: [
    { path: "/repo", branch: "develop", isMain: true },
    { path: "/repo.feature-hung-4-working", branch: "feature/hung-#4-working", isMain: false },
    { path: "/repo.feature-hung-5-asking", branch: "feature/hung-#5-asking", isMain: false },
  ],
  agentsByWorktreePath: new Map([
    ["/repo.feature-hung-4-working", [{ paneId: "p4", status: "working" }]],
    ["/repo.feature-hung-5-asking", [{ paneId: "p5a", status: "idle" }, { paneId: "p5b", status: "blocked" }]],
  ]),
  pullRequests: [{ number: 60, state: "OPEN", headRefName: "feature/hung-#6-reviewing", url: "u" }],
};

function columnOf(board, specId) {
  return board.find((task) => task.id === specId).column;
}

test("buildBoard derives every column from spec and live state", () => {
  const board = buildBoard(specs, liveState);
  assert.equal(columnOf(board, "001-base"), "done");
  assert.equal(columnOf(board, "002-next"), "ready");
  assert.equal(columnOf(board, "003-blocked"), "todo");
  assert.equal(columnOf(board, "004-working"), "inProgress");
  assert.equal(columnOf(board, "005-asking"), "needsYou");
  assert.equal(columnOf(board, "006-reviewing"), "review");
});

test("buildBoard lists blockers and the blocked agent pane", () => {
  const board = buildBoard(specs, liveState);
  assert.deepEqual(board.find((task) => task.id === "003-blocked").blockedBy, ["002-next"]);
  assert.equal(board.find((task) => task.id === "005-asking").agent.paneId, "p5b");
});

test("buildBoard sorts by priority first", () => {
  assert.equal(buildBoard(specs, liveState)[0].id, "007-urgent");
});

test("findSpecIdForBranch matches the issue number, then the slug", () => {
  assert.equal(findSpecIdForBranch("feature/hung-#2-next", specs), "002-next");
  assert.equal(findSpecIdForBranch("fix/blocked", specs), "003-blocked");
  assert.equal(findSpecIdForBranch("feature/hung-2-old-style-name", specs), "002-next");
  assert.equal(findSpecIdForBranch("develop", specs), null);
  assert.equal(findSpecIdForBranch("feature/x-database", specs), null);
});

test("buildBoard keeps a merged PR over an older closed one", () => {
  const pullRequests = [
    { number: 12, state: "MERGED", headRefName: "feature/hung-#2-next", url: "u" },
    { number: 10, state: "CLOSED", headRefName: "feature/hung-#2-next", url: "u" },
  ];
  const board = buildBoard(specs, { ...liveState, pullRequests });
  assert.equal(columnOf(board, "002-next"), "done");
});

test("buildBoard blocks on an unmerged PR dependency and unblocks once merged", () => {
  const specsWithPullRequestDependency = [...specs, buildSpec("008-after-pr.md", { issue: 8, dependsOn: "PR #73 (Connect API) merged first, it adds code" })];
  const openState = { ...liveState, pullRequests: [{ number: 73, state: "OPEN", headRefName: "other", url: "u" }] };
  const mergedState = { ...liveState, pullRequests: [{ number: 73, state: "MERGED", headRefName: "other", url: "u" }] };
  assert.deepEqual(buildBoard(specsWithPullRequestDependency, openState).find((task) => task.id === "008-after-pr").blockedBy, ["PR #73"]);
  assert.equal(columnOf(buildBoard(specsWithPullRequestDependency, mergedState), "008-after-pr"), "ready");
});

test("findIssuesWithoutSpec keeps only open issues no spec mentions", () => {
  const { findIssuesWithoutSpec } = require("../columns");
  const openIssues = [{ number: 2, title: "tracked", url: "a" }, { number: 99, title: "new", url: "b" }];
  assert.deepEqual(findIssuesWithoutSpec(specs, openIssues), [{ number: 99, title: "new", url: "b" }]);
});

test("findUnlinkedWorktrees lists task worktrees whose branch matches no spec", () => {
  const { findUnlinkedWorktrees } = require("../columns");
  const state = {
    ...liveState,
    worktrees: [...liveState.worktrees, { path: "/repo.spike", branch: "spike/hung-#9-try-riverpod-3", isMain: false },
      { path: "/repo.agent", branch: "worktree-agent-a97d7c02ec0dcbff1", isMain: false },
      { path: "/repo.chore", branch: "chore/hung-fix-slack-notify", isMain: false }],
    agentsByWorktreePath: new Map([...liveState.agentsByWorktreePath, ["/repo.spike", [{ paneId: "p9", status: "idle" }]]]),
  };
  assert.deepEqual(findUnlinkedWorktrees(specs, state).map((worktree) => [worktree.branch, worktree.agent.paneId]), [["spike/hung-#9-try-riverpod-3", "p9"]]);
});

test("buildBoard treats a spec as done once its GitHub issue is closed, even without a matching PR", () => {
  const closedState = { ...liveState, closedIssueNumbers: [2] };
  const board = buildBoard(specs, closedState);
  assert.equal(columnOf(board, "002-next"), "done");
  assert.equal(columnOf(board, "003-blocked"), "ready");
});

test("buildBoard keeps a spec without any GitHub issue out of the done column", () => {
  const specWithoutIssue = parseSpec("009-no-issue.md", "## Metadata\n- **Title:** no issue\n---\n");
  const board = buildBoard([specWithoutIssue], { ...liveState, closedIssueNumbers: [2] });
  assert.notEqual(columnOf(board, "009-no-issue"), "done");
});

test("deriveColumn keeps a draft pull request in progress and an open one in review", () => {
  const worktree = { path: "/w", isMain: false };
  const base = { isDone: false, worktree, agent: null, autoRun: null, hasOpenDependencies: false };
  assert.equal(deriveColumn({ ...base, pullRequest: { state: "OPEN", isDraft: true } }), COLUMN.inProgress);
  assert.equal(deriveColumn({ ...base, pullRequest: { state: "OPEN", isDraft: false } }), COLUMN.review);
});

function buildConflictSpec(fileName, { issue, conflictsWith, pr = "Todo" }) {
  const conflictLine = conflictsWith ? [`- **Conflicts with:** ${conflictsWith}`] : [];
  const content = ["## **Status:**", "- Review: Approved", `- PR: ${pr}`, "## Metadata", `- **Title:** ${fileName}`, `- **GitHub Issue:** #${issue}`, ...conflictLine, "---"].join("\n");
  return parseSpec(fileName, content);
}

const conflictSpecs = [
  buildConflictSpec("010-detail.md", { issue: 10 }),
  buildConflictSpec("011-create.md", { issue: 11, conflictsWith: "#10" }),
];
const noLiveWork = { worktrees: [], agentsByWorktreePath: new Map(), pullRequests: [] };
const detailWorktree = { path: "/repo.feature-hung-10-detail", branch: "feature/hung-#10-detail", isMain: false };

test("buildBoard blocks a task while its Conflicts with task is in progress, and frees it when that task is not started", () => {
  const detailInProgress = buildBoard(conflictSpecs, { ...noLiveWork, worktrees: [detailWorktree] });
  assert.deepEqual(detailInProgress.find((task) => task.id === "011-create").blockedBy, ["010-detail"]);
  assert.equal(columnOf(detailInProgress, "011-create"), "todo");
  assert.deepEqual(buildBoard(conflictSpecs, noLiveWork).find((task) => task.id === "011-create").blockedBy, []);
});

test("buildBoard keeps a Conflicts with task blocked while the other task has an open PR, and frees it once that task is done", () => {
  const detailPullRequest = { number: 70, state: "OPEN", isDraft: true, headRefName: "feature/hung-#10-detail", url: "u" };
  const detailInReview = buildBoard(conflictSpecs, { ...noLiveWork, pullRequests: [detailPullRequest] });
  assert.deepEqual(detailInReview.find((task) => task.id === "011-create").blockedBy, ["010-detail"]);
  const detailMerged = buildBoard(conflictSpecs, { ...noLiveWork, pullRequests: [{ ...detailPullRequest, state: "MERGED" }] });
  assert.deepEqual(detailMerged.find((task) => task.id === "011-create").blockedBy, []);
});

test("buildBoard applies Conflicts with in both directions", () => {
  const createWorktree = { path: "/repo.feature-hung-11-create", branch: "feature/hung-#11-create", isMain: false };
  const createInProgress = buildBoard(conflictSpecs, { ...noLiveWork, worktrees: [createWorktree] });
  assert.deepEqual(createInProgress.find((task) => task.id === "010-detail").blockedBy, ["011-create"]);
});
