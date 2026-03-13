const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const RULES_PATH = path.resolve(__dirname, "../../../storage.rules");

let testEnv;
let assertFails;
let assertSucceeds;
let initializeTestEnvironment;
let getBytes;
let ref;
let uploadString;

test.before(async () => {
  ({ initializeTestEnvironment, assertFails, assertSucceeds } = await import(
    "@firebase/rules-unit-testing"
  ));
  ({ getBytes, ref, uploadString } = await import("firebase/storage"));

  testEnv = await initializeTestEnvironment({
    projectId: "demo-turqapp",
    storage: {
      rules: fs.readFileSync(RULES_PATH, "utf8"),
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test("users path denies unauthenticated reads", async () => {
  const uid = "owner-storage";
  const objectPath = `users/${uid}/avatar.png`;

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await uploadString(ref(context.storage(), objectPath), "seed");
  });

  const unauthCtx = testEnv.unauthenticatedContext();
  await assertFails(getBytes(ref(unauthCtx.storage(), objectPath)));
});

test("users path allows owner write and blocks other users", async () => {
  const uid = "owner-write";
  const ownerCtx = testEnv.authenticatedContext(uid);
  const otherCtx = testEnv.authenticatedContext("other-user");
  const objectPath = `users/${uid}/profile/photo.txt`;

  await assertSucceeds(uploadString(ref(ownerCtx.storage(), objectPath), "ok"));
  await assertFails(uploadString(ref(otherCtx.storage(), objectPath), "nope"));
});

test("HLS path is publicly readable but not writable by clients", async () => {
  const objectPath = "Posts/post123/hls/master.m3u8";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await uploadString(ref(context.storage(), objectPath), "#EXTM3U");
  });

  const unauthCtx = testEnv.unauthenticatedContext();
  const authCtx = testEnv.authenticatedContext("some-user");

  await assertSucceeds(getBytes(ref(unauthCtx.storage(), objectPath)));
  await assertFails(uploadString(ref(authCtx.storage(), objectPath), "blocked"));
});

test("story HLS path is publicly readable but not writable by story owner", async () => {
  const uid = "story-owner";
  const objectPath = `stories/${uid}/story123/hls/master.m3u8`;

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await uploadString(ref(context.storage(), objectPath), "#EXTM3U");
  });

  const unauthCtx = testEnv.unauthenticatedContext();
  const ownerCtx = testEnv.authenticatedContext(uid);

  await assertSucceeds(getBytes(ref(unauthCtx.storage(), objectPath)));
  await assertFails(uploadString(ref(ownerCtx.storage(), objectPath), "blocked"));
});
