const test = require("node:test");
const assert = require("node:assert/strict");
const { parseSpec } = require("../specs");
const { buildBoard, findSpecIdForBranch } = require("../columns");

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
