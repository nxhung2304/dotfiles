const test = require("node:test");
const assert = require("node:assert/strict");
const { slugifyStoryTitle, parseUncheckedStoryTasks, findStoryTasksWithoutSpec } = require("../story");

const STORY = [
  "## 3. Course browsing",
  "- [x] Login",
  "    - [ ] nested item",
  "- [ ] Home / Course list (filter: category, level, search)",
  "- [ ] Course detail (sections + lessons, nút Enroll)",
].join("\n");

test("slugifyStoryTitle drops the parenthetical note and joins words with dashes", () => {
  assert.equal(slugifyStoryTitle("Home / Course list (filter: category, level, search)"), "home-course-list");
});

test("parseUncheckedStoryTasks keeps only unchecked top-level tasks", () => {
  assert.deepEqual(parseUncheckedStoryTasks(STORY).map((task) => task.slug), ["home-course-list", "course-detail"]);
});

test("findStoryTasksWithoutSpec skips tasks that already have a spec", () => {
  const remaining = findStoryTasksWithoutSpec(parseUncheckedStoryTasks(STORY), [{ slug: "home-course-list" }]);
  assert.deepEqual(remaining.map((task) => task.slug), ["course-detail"]);
});

test("addSpecWriterStatus marks a task whose [SPEC] workspace has a working Claude", () => {
  const tasks = [{ slug: "course-detail" }, { slug: "lesson-player" }];
  const workspaces = [{ label: "[SPEC] course-detail", workspace_id: "w1" }];
  const agents = [{ agent: "claude", workspace_id: "w1", agent_status: "working" }];
  const result = require("../story").addSpecWriterStatus(tasks, workspaces, agents);
  assert.deepEqual(result.map((task) => task.specWriter), [{ agentStatus: "working" }, null]);
});

test("findReusableSpecPane reuses an idle Claude but not a working or blocked one", () => {
  const { findReusableSpecPane } = require("../story");
  const workspaces = [{ label: "[SPEC] course-detail", workspace_id: "w1" }];
  const agentWith = (agent_status) => [{ agent: "claude", workspace_id: "w1", pane_id: "p1", agent_status }];
  assert.deepEqual(findReusableSpecPane(workspaces, agentWith("idle"), "course-detail"), { paneId: "p1", workspaceId: "w1" });
  assert.equal(findReusableSpecPane(workspaces, agentWith("working"), "course-detail"), null);
  assert.equal(findReusableSpecPane(workspaces, agentWith("blocked"), "course-detail"), null);
  assert.equal(findReusableSpecPane(workspaces, agentWith("idle"), "other"), null);
});
