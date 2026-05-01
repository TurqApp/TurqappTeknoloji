const test = require("node:test");
const assert = require("node:assert/strict");

const {
  rankMotorCandidateDiversity,
} = require("../../lib/14_typesensePosts.js");

test("feed motor diversity caps flood roots and repeated users before refill", () => {
  const ranked = rankMotorCandidateDiversity(
    [
      {
        id: "root-a",
        userID: "user-a",
        floodCount: 3,
        mainFlood: "",
      },
      {
        id: "child-a-1",
        userID: "user-a",
        floodCount: 1,
        mainFlood: "root-a",
      },
      {
        id: "user-b-1",
        userID: "user-b",
        floodCount: 1,
        mainFlood: "",
      },
      {
        id: "user-a-standalone",
        userID: "user-a",
        floodCount: 1,
        mainFlood: "",
      },
      {
        id: "user-a-third",
        userID: "user-a",
        floodCount: 1,
        mainFlood: "",
      },
      {
        id: "root-c",
        userID: "user-c",
        floodCount: 2,
        mainFlood: "",
      },
    ],
    {
      surface: "feed",
      limit: 6,
    },
  );

  assert.deepEqual(
    ranked.preferredHits.map((hit) => hit.id),
    ["root-a", "user-b-1", "user-a-standalone", "root-c"],
  );
  assert.deepEqual(
    ranked.relaxedHits.map((hit) => hit.id),
    [
      "root-a",
      "user-b-1",
      "user-a-standalone",
      "root-c",
      "child-a-1",
      "user-a-third",
    ],
  );
});

test("non-feed motor diversity keeps original order", () => {
  const ranked = rankMotorCandidateDiversity(
    [
      {
        id: "root-a",
        userID: "user-a",
        floodCount: 3,
        mainFlood: "",
      },
      {
        id: "child-a-1",
        userID: "user-a",
        floodCount: 1,
        mainFlood: "root-a",
      },
      {
        id: "user-a-third",
        userID: "user-a",
        floodCount: 1,
        mainFlood: "",
      },
    ],
    {
      surface: "short",
      limit: 3,
    },
  );

  assert.deepEqual(
    ranked.preferredHits.map((hit) => hit.id),
    ["root-a", "child-a-1", "user-a-third"],
  );
  assert.deepEqual(
    ranked.relaxedHits.map((hit) => hit.id),
    ["root-a", "child-a-1", "user-a-third"],
  );
});
