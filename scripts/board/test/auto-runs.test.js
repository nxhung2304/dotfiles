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
const runningRun = { tasks: [{ spec: "024-apply", phase: "plan", status: "running" }] };

test("findActiveAutoRuns links an active run task to the Claude pane of its AUTO workspace", () => {
  const autoRuns = findActiveAutoRuns([runningRun], workspaces, agents);
  assert.deepEqual(autoRuns.get("024-apply"), { paneId: "w31:p1", agentStatus: "working", phase: "plan", runStatus: "running" });
});

test("findActiveAutoRuns ignores finished tasks and runs whose AUTO workspace is gone", () => {
  assert.equal(findActiveAutoRuns([{ tasks: [{ spec: "024-apply", phase: "finalize", status: "done" }] }], workspaces, agents).size, 0);
  assert.equal(findActiveAutoRuns([runningRun], [], agents).size, 0);
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
