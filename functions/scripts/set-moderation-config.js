const admin = require("firebase-admin");

try {
  admin.initializeApp({
    projectId: "turqappteknoloji",
  });
} catch (err) {}

const moderationConfig = {
  enabled: true,
  blackBadgeFlagThreshold: 5,
  allowSingleFlagPerUser: true,
  enableShadowHide: true,
  notifyOwnerOnAdminRemove: true,
  notifyFlaggersOnAdminRemove: true,
  resetFlagsOnRestore: true,
};

async function main() {
  const db = admin.firestore();
  await db.doc("adminConfig/moderation").set(moderationConfig, { merge: true });
  console.log("adminConfig/moderation updated");
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
