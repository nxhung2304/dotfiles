const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");
const { findResumableSession, encodeProjectDirName } = require("../sessions");

function createConfigDir(worktreePath, sessions) {
  const configDir = fs.mkdtempSync(path.join(os.tmpdir(), "board-sessions-"));
  const projectDir = path.join(configDir, "projects", encodeProjectDirName(worktreePath));
  fs.mkdirSync(projectDir, { recursive: true });
  sessions.forEach(({ id, content, ageSeconds }) => {
    const file = path.join(projectDir, `${id}.jsonl`);
    fs.writeFileSync(file, content);
    const time = new Date(Date.now() - ageSeconds * 1000);
    fs.utimesSync(file, time, time);
  });
  return configDir;
}

test("encodeProjectDirName replaces every non-alphanumeric character like Claude Code does", () => {
  assert.equal(
    encodeProjectDirName("/Users/me/Dev/rights/app_name-mobile.feature-hung--87-load"),
    "-Users-me-Dev-rights-app-name-mobile-feature-hung--87-load",
  );
});

test("findResumableSession prefers the session that mentions the pull request", async () => {
  const worktreePath = "/w/app.feature-1";
  const configDir = createConfigDir(worktreePath, [
    { id: "newest", content: "nothing relevant", ageSeconds: 10 },
    { id: "creator", content: 'created https://github.com/o/r/pull/100 done', ageSeconds: 500 },
  ]);
  assert.deepEqual(await findResumableSession({ worktreePath, pullRequestNumber: 100, configDirs: [configDir] }), { sessionId: "creator", reason: "created-pr" });
});

test("findResumableSession falls back to the newest session", async () => {
  const worktreePath = "/w/app.feature-2";
  const configDir = createConfigDir(worktreePath, [
    { id: "old", content: "a", ageSeconds: 900 },
    { id: "new", content: "b", ageSeconds: 5 },
  ]);
  assert.deepEqual(await findResumableSession({ worktreePath, pullRequestNumber: 7, configDirs: [configDir] }), { sessionId: "new", reason: "latest" });
});

test("findResumableSession returns null when the worktree has no session", async () => {
  const configDir = fs.mkdtempSync(path.join(os.tmpdir(), "board-sessions-"));
  assert.equal(await findResumableSession({ worktreePath: "/w/none", configDirs: [configDir] }), null);
});
