const test = require("node:test");
const assert = require("node:assert/strict");

const {
  parseReviewReportedTargetRequest,
} = require("../../lib/24_reports.js");

test("review regression rejects unauthenticated moderation review request", () => {
  assert.throws(
    () =>
      parseReviewReportedTargetRequest(
        {
          aggregateId: "agg-reg-1",
          action: "restore",
        },
        {},
      ),
    (error) =>
      typeof error?.code === "string" &&
      error.code.includes("unauthenticated"),
  );
});

test("review regression rejects unsupported moderation action", () => {
  assert.throws(
    () =>
      parseReviewReportedTargetRequest(
        {
          aggregateId: "agg-reg-2",
          action: "delete_forever",
        },
        {
          auth: {
            uid: "admin-reviewer",
            token: { admin: true },
          },
        },
      ),
    (error) =>
      typeof error?.code === "string" &&
      error.code.includes("invalid-argument"),
  );
});

test("review regression always resolves reviewer from auth context", () => {
  const parsed = parseReviewReportedTargetRequest(
    {
      aggregateId: "agg-reg-3",
      action: "keep_hidden",
      uid: "spoofed-reviewer",
    },
    {
      auth: {
        uid: "trusted-reviewer",
        token: { admin: true },
      },
    },
  );

  assert.deepEqual(parsed, {
    aggregateId: "agg-reg-3",
    action: "keep_hidden",
    reviewerUid: "trusted-reviewer",
  });
});
