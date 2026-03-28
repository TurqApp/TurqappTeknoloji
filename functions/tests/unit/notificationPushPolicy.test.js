const test = require("node:test");
const assert = require("node:assert/strict");

const {
  interactionThrottleType,
  interactionQuietWindowMs,
  notificationBodyFromType,
  isNotificationTypeEnabled,
  isUserNotificationTypeEnabled,
  shouldDispatchNotificationPush,
  mergeNotificationPreferences,
  defaultPushTypes,
} = require("../../lib/notificationPushPolicy.js");

test("notification push policy preserves specific interaction bodies", () => {
  assert.equal(notificationBodyFromType("like"), "gönderini beğendi");
  assert.equal(
    notificationBodyFromType("reshared_posts"),
    "gönderini yeniden paylaştı",
  );
  assert.equal(notificationBodyFromType("Posts"), "gönderinle etkileşime geçti");
});

test("notification push policy throttles generic post activity", () => {
  assert.equal(interactionThrottleType("Posts"), "posts");
  assert.equal(interactionQuietWindowMs("Posts"), 30 * 60 * 1000);
  assert.equal(interactionQuietWindowMs("like"), 30 * 60 * 1000);
  assert.equal(interactionQuietWindowMs("comment"), 2 * 60 * 1000);
});

test("notification push policy disables categories from user preferences", () => {
  const prefs = mergeNotificationPreferences({
    posts: { postActivity: false, comments: true },
    followers: { follows: false },
  });

  assert.equal(isUserNotificationTypeEnabled("like", prefs), false);
  assert.equal(isUserNotificationTypeEnabled("reshared_posts", prefs), false);
  assert.equal(isUserNotificationTypeEnabled("comment", prefs), true);
  assert.equal(isUserNotificationTypeEnabled("follow", prefs), false);
});

test("notification push policy honors messages only and admin type switches", () => {
  const prefs = mergeNotificationPreferences({ messagesOnly: true });
  assert.equal(isUserNotificationTypeEnabled("message", prefs), true);
  assert.equal(isUserNotificationTypeEnabled("like", prefs), false);

  const types = { ...defaultPushTypes, like: false };
  assert.equal(isNotificationTypeEnabled("like", types), false);
  assert.equal(isNotificationTypeEnabled("Posts", types), true);
});

test("notification push policy dispatches only milestone-worthy push payloads", () => {
  assert.equal(shouldDispatchNotificationPush("like", { likeCount: 9 }), false);
  assert.equal(shouldDispatchNotificationPush("like", { likeCount: 10 }), true);
  assert.equal(
    shouldDispatchNotificationPush("posts", { followedPostSubscriber: false }),
    false,
  );
  assert.equal(
    shouldDispatchNotificationPush("posts", { followedPostSubscriber: true }),
    true,
  );
  assert.equal(shouldDispatchNotificationPush("reshared_posts", {}), false);
  assert.equal(shouldDispatchNotificationPush("shared_as_posts", {}), false);
});
