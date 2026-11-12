const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const DEFAULT_RUNS_DIR = path.join(os.homedir(), ".ai-metrics", "orchestrator");
const AUTO_WORKSPACE_LABEL_PREFIX = "[AUTO] ";
const ACTIVE_TASK_STATUSES = ["queued", "running", "needs_you"];
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

function findActiveAutoRuns(runs, workspaces, agents) {
  const autoRunBySpecId = new Map();
  for (const run of runs) {
    for (const task of run.tasks ?? []) {
      if (!ACTIVE_TASK_STATUSES.includes(task.status)) continue;
      const workspace = workspaces.find((candidate) => candidate.label === `${AUTO_WORKSPACE_LABEL_PREFIX}${task.spec}`);
      const agent = workspace && agents.find((candidate) => candidate.agent === CLAUDE_AGENT_LABEL && candidate.workspace_id === workspace.workspace_id);
      if (!agent) continue;
      autoRunBySpecId.set(task.spec, { paneId: agent.pane_id, agentStatus: agent.agent_status, phase: task.phase, runStatus: task.status });
    }
  }
  return autoRunBySpecId;
}

module.exports = { readRunFiles, findActiveAutoRuns };
