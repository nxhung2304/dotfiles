const { runCommand } = require("./command");

const GITHUB_REMOTE_PATTERN = /github\.com[:/]([^/]+)\/(.+?)(?:\.git)?\/?$/;

function toGithubWebUrl(remoteUrl) {
  const match = remoteUrl.trim().match(GITHUB_REMOTE_PATTERN);
  return match ? `https://github.com/${match[1]}/${match[2]}` : null;
}

async function readGithubWebUrl(repoRoot) {
  try {
    return toGithubWebUrl(await runCommand("git", ["remote", "get-url", "origin"], { cwd: repoRoot }));
  } catch (error) {
    console.warn(`[board] cannot read origin remote: ${error.message}`);
    return null;
  }
}

module.exports = { toGithubWebUrl, readGithubWebUrl };
