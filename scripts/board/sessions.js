const fs = require("node:fs");
const os = require("node:os");
const path = require("node:path");

const MAX_SESSIONS_TO_SCAN = 8;
const MAX_TRANSCRIPT_BYTES = 50_000_000;

function listClaudeConfigDirs() {
  const candidates = [process.env.CLAUDE_CONFIG_DIR, path.join(os.homedir(), ".claude"), path.join(os.homedir(), ".claude-personal")];
  return [...new Set(candidates.filter(Boolean))];
}

function encodeProjectDirName(directoryPath) {
  return directoryPath.replace(/[^a-zA-Z0-9]/g, "-");
}

function listSessionFiles(configDirs, worktreePath) {
  const projectDirName = encodeProjectDirName(worktreePath);
  const sessionFiles = [];
  for (const configDir of configDirs) {
    const projectDir = path.join(configDir, "projects", projectDirName);
    if (!fs.existsSync(projectDir)) continue;
    for (const name of fs.readdirSync(projectDir).filter((fileName) => fileName.endsWith(".jsonl"))) {
      const filePath = path.join(projectDir, name);
      const { mtimeMs, size } = fs.statSync(filePath);
      sessionFiles.push({ sessionId: name.slice(0, -".jsonl".length), filePath, mtimeMs, size });
    }
  }
  return sessionFiles.sort((first, second) => second.mtimeMs - first.mtimeMs);
}

async function transcriptMentions(sessionFile, needle) {
  if (sessionFile.size > MAX_TRANSCRIPT_BYTES) return false;
  return (await fs.promises.readFile(sessionFile.filePath, "utf8")).includes(needle);
}

async function findFirstSessionMentioning(sessionFiles, needle) {
  for (const sessionFile of sessionFiles) {
    if (await transcriptMentions(sessionFile, needle)) return sessionFile;
  }
  return null;
}

async function findResumableSession({ worktreePath, pullRequestNumber = null, configDirs = listClaudeConfigDirs() }) {
  const sessionFiles = listSessionFiles(configDirs, worktreePath).slice(0, MAX_SESSIONS_TO_SCAN);
  if (sessionFiles.length === 0) return null;
  if (pullRequestNumber) {
    const creator = await findFirstSessionMentioning(sessionFiles, `/pull/${pullRequestNumber}`);
    if (creator) return { sessionId: creator.sessionId, reason: "created-pr" };
  }
  return { sessionId: sessionFiles[0].sessionId, reason: "latest" };
}

module.exports = { findResumableSession, encodeProjectDirName };
