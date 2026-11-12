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
