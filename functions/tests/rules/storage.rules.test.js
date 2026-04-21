const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const RULES_PATH = path.resolve(__dirname, "../../../storage.rules");

let testEnv;
let assertFails;
let assertSucceeds;
let initializeTestEnvironment;
let doc;
let getBytes;
let ref;
let setDoc;
let uploadString;

test.before(async () => {
  ({ initializeTestEnvironment, assertFails, assertSucceeds } = await import(
    "@firebase/rules-unit-testing"
  ));
  ({ doc, setDoc } = await import("firebase/firestore"));
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

test("shortManifest slot payloads are auth readable and client write blocked", async () => {
  const objectPath = "shortManifest/2026-04-21/slots/slot_001.json";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await uploadString(ref(context.storage(), objectPath), "{\"items\":[]}");
  });

  const authCtx = testEnv.authenticatedContext("short-reader");
  const unauthCtx = testEnv.unauthenticatedContext();

  await assertSucceeds(getBytes(ref(authCtx.storage(), objectPath)));
  await assertFails(getBytes(ref(unauthCtx.storage(), objectPath)));
  await assertFails(uploadString(ref(authCtx.storage(), objectPath), "{}"));
});

test("feedManifest slot payloads are auth readable and client write blocked", async () => {
  const objectPath = "feedManifest/2026-04-21/slots/slot_00.json";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await uploadString(ref(context.storage(), objectPath), "{\"items\":[]}");
  });

  const authCtx = testEnv.authenticatedContext("feed-reader");
  const unauthCtx = testEnv.unauthenticatedContext();

  await assertSucceeds(getBytes(ref(authCtx.storage(), objectPath)));
  await assertFails(getBytes(ref(unauthCtx.storage(), objectPath)));
  await assertFails(uploadString(ref(authCtx.storage(), objectPath), "{}"));
});

test("market storage path allows owner write and blocks other users", async () => {
  const uid = "market-owner";
  const ownerCtx = testEnv.authenticatedContext(uid);
  const otherCtx = testEnv.authenticatedContext("other-market-user");
  const objectPath = `marketStore/${uid}/item123/cover.webp`;

  await assertSucceeds(uploadString(ref(ownerCtx.storage(), objectPath), "ok"));
  await assertFails(uploadString(ref(otherCtx.storage(), objectPath), "nope"));
});

test("post media allows matching uploader metadata without existing post", async () => {
  const uid = "post-uploader";
  const ctx = testEnv.authenticatedContext(uid);
  const objectPath = "Posts/new-post/video.mp4";

  await assertSucceeds(
    uploadString(ref(ctx.storage(), objectPath), "ok", "raw", {
      customMetadata: { uploaderUid: uid },
      contentType: "video/mp4",
    }),
  );
});

test("post media allows owner write when post document already belongs to user", async () => {
  const uid = "post-owner";
  const objectPath = "Posts/existing-post/video.mp4";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "Posts/existing-post"), {
      userID: uid,
    });
  });

  const ctx = testEnv.authenticatedContext(uid);
  await assertSucceeds(
    uploadString(ref(ctx.storage(), objectPath), "ok", "raw", {
      contentType: "video/mp4",
    }),
  );
});

test("post media blocks former bypass uid without matching metadata", async () => {
  const formerBypassUid = "gszJ4gBsCRd03fijoldmtfsAXks2";
  const ctx = testEnv.authenticatedContext(formerBypassUid);
  const objectPath = "Posts/new-post/no-metadata.mp4";

  await assertFails(
    uploadString(ref(ctx.storage(), objectPath), "blocked", "raw", {
      contentType: "video/mp4",
    }),
  );
});

test("job media allows matching uploader metadata without existing job document", async () => {
  const uid = "job-uploader";
  const ctx = testEnv.authenticatedContext(uid);
  const objectPath = "isBul/job-123/logo.webp";

  await assertSucceeds(
    uploadString(ref(ctx.storage(), objectPath), "ok", "raw", {
      customMetadata: { uploaderUid: uid },
      contentType: "image/webp",
    }),
  );
});

test("job media allows owner write when job document already belongs to user", async () => {
  const uid = "job-owner";
  const objectPath = "isBul/job-owned/logo.webp";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "isBul/job-owned"), {
      userID: uid,
    });
  });

  const ctx = testEnv.authenticatedContext(uid);
  await assertSucceeds(
    uploadString(ref(ctx.storage(), objectPath), "ok", "raw", {
      contentType: "image/webp",
    }),
  );
});

test("job media blocks former bypass uid without matching metadata", async () => {
  const formerBypassUid = "gszJ4gBsCRd03fijoldmtfsAXks2";
  const ctx = testEnv.authenticatedContext(formerBypassUid);
  const objectPath = "isBul/job-legacy/logo.webp";

  await assertFails(
    uploadString(ref(ctx.storage(), objectPath), "blocked", "raw", {
      contentType: "image/webp",
    }),
  );
});
