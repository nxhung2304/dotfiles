const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const DEFAULT_RUNS_DIR = path.join(os.homedir(), ".ai-metrics", "orchestrator");
const AUTO_WORKSPACE_LABEL_PREFIX = "[AUTO] ";
const ACTIVE_TASK_STATUSES = ["queued", "running", "needs_you"];
const PROBLEM_TASK_STATUSES = { failed: "vibe-issue báo task này bị lỗi", blocked: "vibe-issue báo task này bị chặn" };
const MISSING_CLAUDE_PROBLEM = "Phiên Claude trong tab [AUTO] không còn chạy";
const CLAUDE_AGENT_LABEL = "claude";

function readRunFiles(runsDir = DEFAULT_RUNS_DIR) {
  let fileNames;
  try {
    fileNames = fs.readdirSync(runsDir).filter((fileName) => /^\d{8}-\d{4}\.json$/.test(fileName)).sort();
  } catch {
    return [];
  }
  const runs = [];
  for (const fileName of fileNames) {
    try {
      runs.push(JSON.parse(fs.readFileSync(path.join(runsDir, fileName), "utf8")));
    } catch {
      continue;
    }
  }
  return runs;
}

function describeProblem(task, agent) {
  if (PROBLEM_TASK_STATUSES[task.status]) return `${PROBLEM_TASK_STATUSES[task.status]} (phase ${task.phase})`;
  return agent ? null : MISSING_CLAUDE_PROBLEM;
}

function findActiveAutoRuns(runs, workspaces, panes, agents) {
  const autoRunBySpecId = new Map();
  for (const run of runs) {
    for (const task of run.tasks ?? []) {
      if (!ACTIVE_TASK_STATUSES.includes(task.status) && !PROBLEM_TASK_STATUSES[task.status]) continue;
      const workspace = workspaces.find((candidate) => candidate.label === `${AUTO_WORKSPACE_LABEL_PREFIX}${task.spec}`);
      if (!workspace) continue;
      const agent = agents.find((candidate) => candidate.agent === CLAUDE_AGENT_LABEL && candidate.workspace_id === workspace.workspace_id);
      const paneId = agent?.pane_id ?? panes.find((pane) => pane.workspace_id === workspace.workspace_id)?.pane_id ?? null;
      autoRunBySpecId.set(task.spec, {
        paneId,
        agentStatus: agent?.agent_status ?? null,
        phase: task.phase,
        runStatus: task.status,
        problem: describeProblem(task, agent),
      });
    }
  }
  return autoRunBySpecId;
}

module.exports = { readRunFiles, findActiveAutoRuns };
