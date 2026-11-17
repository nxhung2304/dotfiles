const test = require("node:test");
const assert = require("node:assert/strict");
const { parseShortStat, extractPreview } = require("../worktree-details");
const { summarizeChecks } = require("../live-state");

test("parseShortStat reads git diff --shortstat output", () => {
  assert.deepEqual(parseShortStat(" 5 files changed, 120 insertions(+), 30 deletions(-)\n"), { filesChanged: 5, insertions: 120, deletions: 30 });
  assert.deepEqual(parseShortStat(" 1 file changed, 1 insertion(+)\n"), { filesChanged: 1, insertions: 1, deletions: 0 });
  assert.deepEqual(parseShortStat(""), { filesChanged: 0, insertions: 0, deletions: 0 });
});

test("extractPreview keeps the last meaningful lines and drops terminal chrome", () => {
  const paneText = [
    "\x1b[1m⏺ Reading lib/ot/ot_repository.dart\x1b[0m",
    "Do you want to keep the old fixed list as fallback?",
    "╭──────────────────────────╮",
    "│ >                        │",
    "╰──────────────────────────╯",
    "  ? for shortcuts",
  ].join("\n");
  assert.deepEqual(extractPreview(paneText), ["⏺ Reading lib/ot/ot_repository.dart", "Do you want to keep the old fixed list as fallback?"]);
});

test("summarizeChecks reduces check runs to failing, pending or passing", () => {
  assert.equal(summarizeChecks([{ conclusion: "SUCCESS" }, { conclusion: "FAILURE" }]), "failing");
  assert.equal(summarizeChecks([{ conclusion: "SUCCESS" }, { status: "IN_PROGRESS", conclusion: "" }]), "pending");
  assert.equal(summarizeChecks([{ conclusion: "SUCCESS" }, { state: "SUCCESS" }]), "passing");
  assert.equal(summarizeChecks([]), null);
});
