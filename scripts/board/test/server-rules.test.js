const test = require("node:test");
const assert = require("node:assert/strict");
const { createCooldownTracker, selectTasksToAutoCleanUp, isLocalAddress } = require("../server-rules");

test("cooldown tracker blocks an id only until the cooldown passes", () => {
  let now = 1_000;
  const cooldown = createCooldownTracker(100, () => now);
  assert.equal(cooldown.isCoolingDown("a"), false);
  cooldown.markStarted("a");
  assert.equal(cooldown.isCoolingDown("a"), true);
  assert.equal(cooldown.isCoolingDown("b"), false);
  now += 100;
  assert.equal(cooldown.isCoolingDown("a"), false);
});

test("selectTasksToAutoCleanUp returns nothing while herdr is unreadable", () => {
  const mergedCleanTask = {
    id: "t",
    column: "done",
    pullRequest: { state: "MERGED" },
    worktree: { path: "/w", isMain: false },
    agent: null,
    diffStats: { uncommittedFileCount: 0 },
  };
  assert.deepEqual(selectTasksToAutoCleanUp({ tasks: [mergedCleanTask], isHerdrAvailable: true }), [mergedCleanTask]);
  assert.deepEqual(selectTasksToAutoCleanUp({ tasks: [mergedCleanTask], isHerdrAvailable: false }), []);
});

test("isLocalAddress accepts loopback and own addresses only", () => {
  assert.equal(isLocalAddress("::ffff:127.0.0.1", []), true);
  assert.equal(isLocalAddress("::1", []), true);
  assert.equal(isLocalAddress("192.168.1.5", ["192.168.1.5"]), true);
  assert.equal(isLocalAddress("192.168.1.9", ["192.168.1.5"]), false);
  assert.equal(isLocalAddress(undefined, []), false);
});
