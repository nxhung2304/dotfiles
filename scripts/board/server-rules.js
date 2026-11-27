const { isWorktreeSafeToAutoCleanUp } = require("./actions");

function createCooldownTracker(cooldownMs, readNow = Date.now) {
  const startedAtById = new Map();
  return {
    isCoolingDown: (id) => readNow() - (startedAtById.get(id) ?? -Infinity) < cooldownMs,
    markStarted: (id) => startedAtById.set(id, readNow()),
  };
}

function selectTasksToAutoCleanUp({ tasks, isHerdrAvailable }) {
  return isHerdrAvailable ? tasks.filter(isWorktreeSafeToAutoCleanUp) : [];
}

function isLocalAddress(remoteAddress, ownAddresses) {
  const address = (remoteAddress ?? "").replace(/^::ffff:/, "");
  return address === "127.0.0.1" || address === "::1" || ownAddresses.includes(address);
}

module.exports = { createCooldownTracker, selectTasksToAutoCleanUp, isLocalAddress };
