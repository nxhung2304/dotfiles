const test = require("node:test");
const assert = require("node:assert/strict");
const { findActiveAutoRuns } = require("../auto-runs");
const { parseSpec } = require("../specs");
const { buildBoard } = require("../columns");

const workspaces = [{ workspace_id: "w31", label: "[AUTO] 024-apply" }];
const agents = [
  { agent: "claude", pane_id: "w31:p1", workspace_id: "w31", agent_status: "working" },
  { agent: "claude", pane_id: "w2D:pH", workspace_id: "w2D", agent_status: "idle" },
];
const panes = [{ pane_id: "w31:p1", workspace_id: "w31" }];
const runningRun = { tasks: [{ spec: "024-apply", phase: "plan", status: "running" }] };

test("findActiveAutoRuns links an active run task to the Claude pane of its AUTO workspace", () => {
  const autoRuns = findActiveAutoRuns([runningRun], workspaces, panes, agents);
  assert.deepEqual(autoRuns.get("024-apply"), { paneId: "w31:p1", agentStatus: "working", phase: "plan", runStatus: "running", problem: null });
});

test("findActiveAutoRuns ignores finished tasks and runs whose AUTO workspace is gone", () => {
  assert.equal(findActiveAutoRuns([{ tasks: [{ spec: "024-apply", phase: "finalize", status: "done" }] }], workspaces, panes, agents).size, 0);
  assert.equal(findActiveAutoRuns([runningRun], [], panes, agents).size, 0);
});

test("buildBoard puts a task with an active auto run in progress, or needs you when the run waits for the user", () => {
  const specContent = ["## **Status:**", "- Review: Pending", "- PR: Todo", "## Metadata", "- **Title:** t", "- **GitHub Issue:** #24", "- **Depends on:** —", "---"].join("\n");
  const specs = [parseSpec("024-apply.md", specContent)];
  const baseState = { worktrees: [], pullRequests: [], agentsByWorktreePath: new Map(), openIssues: [] };
  const running = new Map([["024-apply", { paneId: "w31:p1", agentStatus: "working", phase: "plan", runStatus: "running" }]]);
  const waiting = new Map([["024-apply", { paneId: "w31:p1", agentStatus: "idle", phase: "plan", runStatus: "needs_you" }]]);
  assert.equal(buildBoard(specs, { ...baseState, autoRunBySpecId: running })[0].column, "inProgress");
  assert.equal(buildBoard(specs, { ...baseState, autoRunBySpecId: waiting })[0].column, "needsYou");
  assert.equal(buildBoard(specs, { ...baseState, autoRunBySpecId: new Map() })[0].column, "ready");
});

test("findActiveAutoRuns reports a failed task, and a running task whose Claude session is gone", () => {
  const failedRun = { tasks: [{ spec: "024-apply", phase: "code", status: "failed" }] };
  assert.equal(findActiveAutoRuns([failedRun], workspaces, panes, agents).get("024-apply").problem, "vibe-issue báo task này bị lỗi (phase code)");
  const withoutClaude = findActiveAutoRuns([runningRun], workspaces, panes, []).get("024-apply");
  assert.equal(withoutClaude.paneId, "w31:p1");
  assert.equal(withoutClaude.problem, "Phiên Claude trong tab [AUTO] không còn chạy");
});

test("buildBoard shows an auto run with a problem under needs you", () => {
  const specContent = ["## **Status:**", "- Review: Approved", "- PR: Todo", "## Metadata", "- **Title:** t", "- **GitHub Issue:** #24", "- **Depends on:** —", "---"].join("\n");
  const specs = [parseSpec("024-apply.md", specContent)];
  const problemRun = new Map([["024-apply", { paneId: "w31:p1", agentStatus: "idle", phase: "code", runStatus: "failed", problem: "lỗi" }]]);
  const board = buildBoard(specs, { worktrees: [], pullRequests: [], agentsByWorktreePath: new Map(), openIssues: [], autoRunBySpecId: problemRun });
  assert.equal(board[0].column, "needsYou");
  assert.equal(board[0].autoRun.problem, "lỗi");
});
