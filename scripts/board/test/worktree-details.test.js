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

test("extractPreview drops the input box and footer of a real Claude pane", () => {
  const rule = "─".repeat(40);
  const paneText = [
    "⏺ Kết luận: đã chuyển file sang checkout chính.",
    "",
    "✻ Sautéed for 11s · done",
    "",
    rule,
    "❯",
    rule,
    "  rights_vn-office_management-mobile › [WT] feature-hung--87-load-ot",
    "  Opus 5.5 · ctx 14%, 7 day: 73% (5,4h left)",
    "  ⏵⏵ auto mode on (shift+tab to cycle) · ← 5 agents",
  ].join("\n");
  assert.deepEqual(extractPreview(paneText), ["⏺ Kết luận: đã chuyển file sang checkout chính.", "✻ Sautéed for 11s · done"]);
});

test("extractPreview keeps the question and options of a blocked agent dialog", () => {
  const rule = "─".repeat(40);
  const paneText = [
    rule,
    " ☐ A hay B",
    "",
    "Bạn chọn A hay B?",
    "",
    "❯ 1. A",
    "     Lựa chọn A",
    "  2. B",
    "     Lựa chọn B",
    "  3. Type something.",
    rule,
    "  4. Chat about this",
    "",
    "Enter to select · ↑/↓ to navigate · Esc to cancel",
  ].join("\n");
  assert.deepEqual(extractPreview(paneText, 6), ["Bạn chọn A hay B?", "❯ 1. A", "Lựa chọn A", "2. B", "Lựa chọn B", "3. Type something."]);
});
