const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { readSpecDetail, readIssueDetail } = require("../details");

test("readSpecDetail reads the spec file from the repo root", () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "board-detail-"));
  fs.mkdirSync(path.join(root, "specs", "issues"), { recursive: true });
  fs.writeFileSync(path.join(root, "specs", "issues", "001-a.md"), "# Hello");
  const detail = readSpecDetail(root, { id: "001-a", title: "A", specPath: path.join("specs", "issues", "001-a.md") });
  assert.equal(detail.content, "# Hello");
});

test("readSpecDetail prefers the worktree that owns a branch-only spec", () => {
  const repoRoot = fs.mkdtempSync(path.join(os.tmpdir(), "board-detail-"));
  const worktreeRoot = fs.mkdtempSync(path.join(os.tmpdir(), "board-detail-wt-"));
  fs.mkdirSync(path.join(worktreeRoot, "specs", "issues"), { recursive: true });
  fs.writeFileSync(path.join(worktreeRoot, "specs", "issues", "002-b.md"), "branch only");
  const detail = readSpecDetail(repoRoot, { id: "002-b", title: "B", specPath: path.join("specs", "issues", "002-b.md"), sourceRoot: worktreeRoot });
  assert.equal(detail.content, "branch only");
});

test("readSpecDetail reports a missing file as a 404", () => {
  assert.throws(() => readSpecDetail("/nonexistent", { id: "x", title: "x", specPath: "specs/issues/x.md" }), (error) => error.httpStatus === 404);
});

test("readIssueDetail maps the gh issue fields", async () => {
  const runJson = async () => ({ number: 78, title: "T", state: "OPEN", url: "u", body: null, labels: [{ name: "ui" }], author: { login: "me" }, createdAt: "d", comments: [{}, {}] });
  const detail = await readIssueDetail("/repo", 78, runJson);
  assert.deepEqual([detail.labels, detail.body, detail.commentCount, detail.author], [["ui"], "", 2, "me"]);
});

test("readIssueDetail rejects a non-numeric issue number before running gh", async () => {
  let wasCalled = false;
  await assert.rejects(() => readIssueDetail("/repo", Number.NaN, async () => { wasCalled = true; }), (error) => error.httpStatus === 404);
  assert.equal(wasCalled, false);
});
