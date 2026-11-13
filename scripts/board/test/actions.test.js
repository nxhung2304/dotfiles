const test = require("node:test");
const assert = require("node:assert/strict");
const { buildStartPrompt } = require("../actions");

const approvedSpecTask = { id: "89-firebase-crashlytics", specPath: "specs/issues/89-firebase-crashlytics.md", isApproved: true, githubIssues: [89] };

test("buildStartPrompt for an approved spec skips implement-prepare and runs code, quality, finalize", () => {
  const prompt = buildStartPrompt(approvedSpecTask, "feature/hung-#89-firebase-crashlytics", { isNewBranch: true, startPoint: "origin/develop" });
  assert.match(prompt, /do not run implement-prepare/);
  assert.match(prompt, /implement-code with 89-firebase-crashlytics/);
  assert.match(prompt, /base_branch origin\/develop/);
  assert.doesNotMatch(prompt, /^\/implement-issue/);
});

test("buildStartPrompt for a spec that is not approved starts the spec review", () => {
  const prompt = buildStartPrompt({ ...approvedSpecTask, isApproved: false }, "feature/x", { isNewBranch: true, startPoint: "origin/develop" });
  assert.equal(prompt, "/review-specs #89");
});

test("buildAutoRunPrompt runs vibe-issue for one task at a time", () => {
  const { buildAutoRunPrompt } = require("../actions");
  assert.equal(buildAutoRunPrompt(approvedSpecTask), "/vibe-issue 89-firebase-crashlytics max-parallel=1");
});

test("ensureTaskCanRunAutomatically refuses a folder of docs and a blocked task", () => {
  const { ensureTaskCanRunAutomatically } = require("../actions");
  const readyTask = { ...approvedSpecTask, column: "ready", blockedBy: [], onlyInBranch: null };
  assert.doesNotThrow(() => ensureTaskCanRunAutomatically(readyTask));
  assert.throws(() => ensureTaskCanRunAutomatically({ ...readyTask, specPath: "specs/issues/89-x/issue.md" }), /vibe-issue chỉ chạy task có file spec/);
  assert.throws(() => ensureTaskCanRunAutomatically({ ...readyTask, blockedBy: ["024"] }), /bị chặn/);
});

test("buildAutoRunPrompt adds auto-approve-spec only when asked and the spec is not approved", () => {
  const { buildAutoRunPrompt } = require("../actions");
  const unapprovedTask = { ...approvedSpecTask, isApproved: false };
  assert.equal(buildAutoRunPrompt(unapprovedTask, true), "/vibe-issue 89-firebase-crashlytics max-parallel=1 auto-approve-spec=true");
  assert.equal(buildAutoRunPrompt(unapprovedTask, false), "/vibe-issue 89-firebase-crashlytics max-parallel=1");
  assert.equal(buildAutoRunPrompt(approvedSpecTask, true), "/vibe-issue 89-firebase-crashlytics max-parallel=1");
});

test("buildCreateSpecPrompt uses the skill command for one issue and a list instruction for several", () => {
  const { buildCreateSpecPrompt } = require("../actions");
  assert.equal(buildCreateSpecPrompt([96], "owner/repo"), "/github-issues-to-md 96 owner/repo");
  assert.equal(buildCreateSpecPrompt([96], null), "/github-issues-to-md 96");
  assert.match(buildCreateSpecPrompt([96, 84], "owner/repo"), /github-issues-to-md skill once for each .*owner\/repo.*#96, #84/);
});

test("buildAgentStartArgs passes --resume after the separator only when a session is known", () => {
  const { buildAgentStartArgs } = require("../actions");
  assert.deepEqual(buildAgentStartArgs("w1:1", null), ["agent", "start", "claude-w1-1", "--kind", "claude", "--pane", "w1:1"]);
  assert.deepEqual(buildAgentStartArgs("w1:1", "abc"), ["agent", "start", "claude-w1-1", "--kind", "claude", "--pane", "w1:1", "--", "--resume", "abc"]);
});
