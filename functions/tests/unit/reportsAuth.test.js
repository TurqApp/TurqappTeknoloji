const test = require("node:test");
const assert = require("node:assert/strict");

const {
  parseReviewReportedTargetRequest,
} = require("../../lib/24_reports.js");

test("reviewReportedTarget rejects unauthenticated fallback uid", () => {
  assert.throws(
    () =>
      parseReviewReportedTargetRequest(
        {
          uid: "allowed-admin-uid",
          aggregateId: "agg-1",
          action: "restore",
        },
        {},
      ),
    (error) =>
      typeof error?.code === "string" &&
      error.code.includes("unauthenticated"),
  );
});

test("reviewReportedTarget uses auth uid instead of spoofed data uid", () => {
  const parsed = parseReviewReportedTargetRequest(
    {
      uid: "spoofed-admin-uid",
      aggregateId: "agg-2",
      action: "keep_hidden",
    },
    {
      auth: {
        uid: "real-admin-uid",
        token: { admin: true },
      },
    },
  );

  assert.deepEqual(parsed, {
    aggregateId: "agg-2",
    action: "keep_hidden",
    reviewerUid: "real-admin-uid",
  });
});
