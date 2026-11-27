const fs = require("node:fs");
const path = require("node:path");

const STORY_RELATIVE_PATH = path.join("specs", "story.md");
const SPEC_WORKSPACE_LABEL_PREFIX = "[SPEC] ";
const CLAUDE_AGENT_LABEL = "claude";
const UNCHECKED_TOP_LEVEL_TASK = /^- \[ \]\s+(.+?)\s*$/;

function slugifyStoryTitle(title) {
  return title
    .replace(/\([^)]*\)/g, " ")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "");
}

function parseUncheckedStoryTasks(content) {
  return content
    .split("\n")
    .map((line) => UNCHECKED_TOP_LEVEL_TASK.exec(line)?.[1])
    .filter(Boolean)
    .map((title) => ({ title, slug: slugifyStoryTitle(title) }))
    .filter((task) => task.slug !== "");
}

function findStoryTasksWithoutSpec(storyTasks, specs) {
  const specSlugs = new Set(specs.map((spec) => spec.slug));
  return storyTasks.filter((task) => !specSlugs.has(task.slug));
}

function addSpecWriterStatus(storyTasks, workspaces, agents) {
  return storyTasks.map((task) => {
    const workspace = workspaces.find((candidate) => candidate.label === `${SPEC_WORKSPACE_LABEL_PREFIX}${task.slug}`);
    if (!workspace) return { ...task, specWriter: null };
    const agent = agents.find((candidate) => candidate.agent === CLAUDE_AGENT_LABEL && candidate.workspace_id === workspace.workspace_id);
    return { ...task, specWriter: { agentStatus: agent?.agent_status ?? null } };
  });
}

const REUSABLE_AGENT_STATUSES = ["idle", "done"];

function findReusableSpecPane(workspaces, agents, slug) {
  const workspace = workspaces.find((candidate) => candidate.label === `${SPEC_WORKSPACE_LABEL_PREFIX}${slug}`);
  if (!workspace) return null;
  const agent = agents.find(
    (candidate) => candidate.agent === CLAUDE_AGENT_LABEL && candidate.workspace_id === workspace.workspace_id && REUSABLE_AGENT_STATUSES.includes(candidate.agent_status),
  );
  return agent ? { paneId: agent.pane_id, workspaceId: workspace.workspace_id } : null;
}

function loadStoryTasksWithoutSpec(repoRoot, specs) {
  const storyPath = path.join(repoRoot, STORY_RELATIVE_PATH);
  if (!fs.existsSync(storyPath)) return [];
  return findStoryTasksWithoutSpec(parseUncheckedStoryTasks(fs.readFileSync(storyPath, "utf8")), specs);
}

module.exports = { slugifyStoryTitle, parseUncheckedStoryTasks, findStoryTasksWithoutSpec, addSpecWriterStatus, findReusableSpecPane, loadStoryTasksWithoutSpec, STORY_RELATIVE_PATH };
