const { execFile } = require("node:child_process");

const COMMAND_TIMEOUT_MS = 30_000;

function describeSilentFailure(error) {
  if (error.killed) return `timed out after ${COMMAND_TIMEOUT_MS / 1000}s`;
  if (error.signal) return `killed by ${error.signal}`;
  if (typeof error.code === "number") return `exit code ${error.code}`;
  return error.message;
}

function runCommand(command, args, options = {}) {
  return new Promise((resolve, reject) => {
    execFile(command, args, { timeout: COMMAND_TIMEOUT_MS, ...options }, (error, stdout, stderr) => {
      if (error) {
        error.message = `${command} ${args.join(" ")} failed: ${stderr.trim() || describeSilentFailure(error)}`;
        reject(error);
        return;
      }
      resolve(stdout);
    });
  });
}

async function runJsonCommand(command, args, options) {
  return JSON.parse(await runCommand(command, args, options));
}

module.exports = { runCommand, runJsonCommand };
