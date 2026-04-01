const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");

const {
  HYBRID_FEED_CONTRACT,
  HYBRID_FEED_REFERENCE_FIELD_NAMES,
} = require("../../lib/hybridFeedContract.js");

test("hybrid feed contract exposes canonical client-aligned identifiers", () => {
  assert.equal(HYBRID_FEED_CONTRACT.contractId, "feed_home_primary_hybrid_v1");
  assert.equal(HYBRID_FEED_CONTRACT.primaryCollection, "userFeeds");
  assert.equal(HYBRID_FEED_CONTRACT.primaryItemsSubcollection, "items");
  assert.equal(HYBRID_FEED_CONTRACT.celebrityCollection, "celebAccounts");
  assert.equal(HYBRID_FEED_CONTRACT.usesPrimaryFeedPaging, true);
});

test("hybrid feed contract keeps required reference fields stable", () => {
  assert.deepEqual(
    HYBRID_FEED_REFERENCE_FIELD_NAMES,
    ["postId", "authorId", "timeStamp", "isCelebrity", "expiresAt"],
  );
});

test("client feed contract keeps the same backend-aligned identifiers", () => {
  const clientContractSource = fs.readFileSync(
    path.resolve(__dirname, "../../../lib/Core/Repositories/feed_home_contract.dart"),
    "utf8",
  );

  assert.match(clientContractSource, /feed_home_primary_hybrid_v1/);
  assert.match(clientContractSource, /primaryCollection: 'userFeeds'/);
  assert.match(clientContractSource, /primaryItemsSubcollection: 'items'/);
  assert.match(clientContractSource, /celebrityCollection: 'celebAccounts'/);
});
