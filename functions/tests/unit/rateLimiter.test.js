const test = require("node:test");
const assert = require("node:assert/strict");

const { enforceRateLimit } = require("../../lib/rateLimiter.js");

test("enforceRateLimit allows requests while under limit", () => {
  const uid = `allow-${Date.now()}-${Math.random()}`;
  assert.doesNotThrow(() => {
    enforceRateLimit(uid, "unit_allow", 2, 60);
    enforceRateLimit(uid, "unit_allow", 2, 60);
  });
});

test("enforceRateLimit throws resource-exhausted when limit is exceeded", () => {
  const uid = `deny-${Date.now()}-${Math.random()}`;
  enforceRateLimit(uid, "unit_deny", 1, 60);

  assert.throws(
    () => enforceRateLimit(uid, "unit_deny", 1, 60),
    (error) =>
      typeof error?.code === "string" &&
      error.code.includes("resource-exhausted"),
  );
});
