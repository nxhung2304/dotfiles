const test = require("node:test");
const assert = require("node:assert/strict");
const { createCachedReader } = require("../live-state");

function createSequence(results) {
  let callCount = 0;
  const read = async () => results[Math.min(callCount++, results.length - 1)];
  return { read, getCallCount: () => callCount };
}

test("createCachedReader keeps the last good data when a refresh fails", async (context) => {
  context.mock.timers.enable({ apis: ["Date"] });
  const good = { isAvailable: true, pullRequests: [{ number: 1 }] };
  const failed = { isAvailable: false, error: "gh failed", pullRequests: [] };
  const sequence = createSequence([good, failed, good]);
  const read = createCachedReader(sequence.read, 60_000, { keepLastGood: true });
  assert.equal((await read()).error, undefined);
  context.mock.timers.tick(61_000);
  const afterFailure = await read();
  assert.deepEqual(afterFailure.pullRequests, [{ number: 1 }]);
  assert.match(afterFailure.error, /gh failed/);
  context.mock.timers.tick(11_000);
  const recovered = await read();
  assert.equal(recovered.error, undefined);
  assert.equal(sequence.getCallCount(), 3);
});

test("createCachedReader without keepLastGood returns the failure as is", async (context) => {
  context.mock.timers.enable({ apis: ["Date"] });
  const sequence = createSequence([{ isAvailable: true, items: [1] }, { isAvailable: false, error: "boom", items: [] }]);
  const read = createCachedReader(sequence.read, 1_000);
  await read();
  context.mock.timers.tick(2_000);
  assert.deepEqual((await read()).items, []);
});

test("createCachedReader retries a failed first read sooner than the normal interval", async (context) => {
  context.mock.timers.enable({ apis: ["Date"] });
  const sequence = createSequence([{ isAvailable: false, error: "boom", items: [] }, { isAvailable: true, items: [1] }]);
  const read = createCachedReader(sequence.read, 60_000, { keepLastGood: true });
  await read();
  context.mock.timers.tick(11_000);
  assert.deepEqual((await read()).items, [1]);
});
