const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const RULES_PATH = path.resolve(__dirname, "../../../firestore.rules");

let testEnv;
let assertSucceeds;
let initializeTestEnvironment;
let doc;
let setDoc;

test.before(async () => {
  ({ initializeTestEnvironment, assertSucceeds } = await import(
    "@firebase/rules-unit-testing"
  ));
  ({ doc, setDoc } = await import("firebase/firestore"));
  testEnv = await initializeTestEnvironment({
    projectId: "demo-turqapp",
    firestore: {
      rules: fs.readFileSync(RULES_PATH, "utf8"),
    },
  });
});

test.after(async () => {
  await testEnv.cleanup();
});

test.afterEach(async () => {
  await testEnv.clearFirestore();
});

test("queue pending shell payload is allowed", async () => {
  const uid = "uUsEkliO8sRaE283UVSV6CxDiqo1";
  const ctx = testEnv.authenticatedContext(uid);
  const ref = doc(
    ctx.firestore(),
    "Posts/ec5b9045-a653-4124-9a2a-374d9c0fb9f7_0",
  );

  await assertSucceeds(
    setDoc(
      ref,
      {
        scheduledAt: 0,
        timeStamp: 1778015674815,
        userID: uid,
        isUploading: true,
        hlsStatus: "none",
      },
      { merge: true },
    ),
  );
});

test("pending shell can be promoted to full post payload", async () => {
  const uid = "uUsEkliO8sRaE283UVSV6CxDiqo1";
  const ctx = testEnv.authenticatedContext(uid);
  const ref = doc(
    ctx.firestore(),
    "Posts/promote-shell-post-test_0",
  );

  await assertSucceeds(
    setDoc(
      ref,
      {
        scheduledAt: 0,
        timeStamp: 1778016380748,
        userID: uid,
        isUploading: true,
        hlsStatus: "none",
      },
      { merge: true },
    ),
  );

  await assertSucceeds(
    setDoc(
      ref,
      {
        arsiv: true,
        debugMode: false,
        deletedPost: false,
        deletedPostTime: 0,
        flood: false,
        floodCount: 1,
        gizlendi: false,
        img: [],
        imgMap: [],
        isAd: false,
        ad: false,
        izBirakYayinTarihi: 1778016380748,
        konum: "",
        mainFlood: "",
        metin: "",
        scheduledAt: 0,
        sikayetEdildi: false,
        stabilized: false,
        stats: {
          commentCount: 0,
          likeCount: 0,
          reportedCount: 0,
          retryCount: 0,
          savedCount: 0,
          statsCount: 0,
        },
        tags: [],
        thumbnail: "",
        timeStamp: 1778016380748,
        userID: uid,
        authorNickname: "turqapp",
        authorDisplayName: "TurqApp",
        authorAvatarUrl: "",
        nickname: "turqapp",
        username: "turqapp",
        fullName: "TurqApp",
        displayName: "TurqApp",
        avatarUrl: "",
        rozet: "",
        video: "",
        isUploading: true,
        yorumMap: {
          visibility: 0,
        },
        reshareMap: {
          visibility: 0,
        },
        hlsStatus: "processing",
        hlsMasterUrl: "",
        hlsUpdatedAt: 0,
        originalUserID: "",
        originalPostID: "",
        sourcePostID: "",
        sharedAsPost: false,
        quotedPost: false,
        quotedOriginalText: "",
        quotedSourceUserID: "",
        quotedSourceDisplayName: "",
        quotedSourceUsername: "",
        quotedSourceAvatarUrl: "",
      },
      { merge: true },
    ),
  );
});

test("queue processor shell promote payload is allowed exactly", async () => {
  const uid = "uUsEkliO8sRaE283UVSV6CxDiqo1";
  const ctx = testEnv.authenticatedContext(uid);
  const ref = doc(
    ctx.firestore(),
    "Posts/queue-shell-promote-exact-test_0",
  );

  await assertSucceeds(
    setDoc(
      ref,
      {
        scheduledAt: 0,
        timeStamp: 1778016380748,
        userID: uid,
        isUploading: true,
        hlsStatus: "none",
      },
      { merge: true },
    ),
  );

  await assertSucceeds(
    setDoc(
      ref,
      {
        arsiv: true,
        debugMode: false,
        deletedPost: false,
        deletedPostTime: 0,
        flood: false,
        floodCount: 1,
        gizlendi: false,
        img: [],
        imgMap: [],
        isAd: false,
        ad: false,
        izBirakYayinTarihi: 1778016380748,
        konum: "",
        mainFlood: "",
        metin: "",
        scheduledAt: 0,
        sikayetEdildi: false,
        stabilized: false,
        stats: {
          commentCount: 0,
          likeCount: 0,
          reportedCount: 0,
          retryCount: 0,
          savedCount: 0,
          statsCount: 0,
        },
        tags: [],
        thumbnail: "",
        timeStamp: 1778016380748,
        userID: uid,
        authorNickname: "turqapp",
        authorDisplayName: "TurqApp",
        authorAvatarUrl: "",
        nickname: "turqapp",
        username: "turqapp",
        fullName: "TurqApp",
        displayName: "TurqApp",
        avatarUrl: "",
        rozet: "",
        video: "",
        isUploading: true,
        hlsStatus: "none",
        hlsMasterUrl: "",
        hlsUpdatedAt: 0,
        yorumMap: {
          visibility: 0,
        },
        reshareMap: {
          visibility: 0,
        },
        originalUserID: "",
        originalPostID: "",
        sourcePostID: "",
        sharedAsPost: false,
        quotedPost: false,
        quotedOriginalText: "",
        quotedSourceUserID: "",
        quotedSourceDisplayName: "",
        quotedSourceUsername: "",
        quotedSourceAvatarUrl: "",
      },
      { merge: true },
    ),
  );
});

test("post creator publish payload can replace upload shell", async () => {
  const uid = "uUsEkliO8sRaE283UVSV6CxDiqo1";
  const ctx = testEnv.authenticatedContext(uid);
  const ref = doc(
    ctx.firestore(),
    "Posts/post-creator-publish-shell-test_0",
  );

  await assertSucceeds(
    setDoc(
      ref,
      {
        userID: uid,
        timeStamp: 1778016635532,
        isUploading: true,
        hlsStatus: "none",
      },
      { merge: true },
    ),
  );

  await assertSucceeds(
    setDoc(
      ref,
      {
        arsiv: false,
        aspectRatio: 1.7778,
        debugMode: false,
        deletedPost: false,
        deletedPostTime: 0,
        flood: false,
        floodCount: 1,
        gizlendi: false,
        img: [],
        imgMap: [],
        isUploading: true,
        isAd: false,
        ad: false,
        izBirakYayinTarihi: 1778016635532,
        stats: {
          commentCount: 0,
          likeCount: 0,
          reportedCount: 0,
          retryCount: 0,
          savedCount: 0,
          statsCount: 0,
        },
        konum: "",
        locationCity: "",
        mainFlood: "",
        metin: "",
        reshareMap: {
          visibility: 1,
        },
        scheduledAt: 0,
        sikayetEdildi: false,
        stabilized: false,
        tags: [],
        thumbnail: "https://cdn.turqapp.com/Posts/post-creator-publish-shell-test_0/thumbnail.webp",
        thumbnailGeneration: {
          strategy: "auto_early_frame",
          frameMs: 0,
          version: 2,
          generatedAt: 1778016635532,
        },
        timeStamp: 1778016635532,
        userID: uid,
        authorNickname: "yunuspaksoy",
        authorDisplayName: "Yunus Paksoy",
        authorAvatarUrl: "",
        nickname: "yunuspaksoy",
        username: "yunuspaksoy",
        fullName: "Yunus Paksoy",
        displayName: "Yunus Paksoy",
        avatarUrl: "",
        rozet: "",
        video: "",
        videoLook: {
          preset: "default",
          version: 1,
          intensity: 1.0,
        },
        hlsStatus: "processing",
        hlsMasterUrl: "",
        hlsUpdatedAt: 0,
        yorumMap: {
          visibility: 1,
        },
        originalUserID: "",
        originalPostID: "",
        sourcePostID: "",
        sharedAsPost: false,
        quotedPost: false,
        quotedOriginalText: "",
        quotedSourceUserID: "",
        quotedSourceDisplayName: "",
        quotedSourceUsername: "",
        quotedSourceAvatarUrl: "",
      },
      { merge: false },
    ),
  );
});

test("pending shell can be promoted after server adds short-link fields", async () => {
  const uid = "uUsEkliO8sRaE283UVSV6CxDiqo1";
  const authed = testEnv.authenticatedContext(uid);
  const admin = testEnv.unauthenticatedContext();
  const ref = doc(
    authed.firestore(),
    "Posts/promote-shell-with-server-fields-test_0",
  );
  const adminRef = doc(
    admin.firestore(),
    "Posts/promote-shell-with-server-fields-test_0",
  );

  await assertSucceeds(
    setDoc(
      ref,
      {
        scheduledAt: 0,
        timeStamp: 1778018077478,
        userID: uid,
        isUploading: true,
        hlsStatus: "none",
      },
      { merge: true },
    ),
  );

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(
      doc(
        context.firestore(),
        "Posts/promote-shell-with-server-fields-test_0",
      ),
      {
        authorNickname: "turqapp",
        authorDisplayName: "TurqApp",
        authorAvatarUrl: "",
        rozet: "",
        shortId: "abc123",
        shortUrl: "https://turqapp.com/p/abc123",
        shortLinkStatus: "ready",
        shortLinkUpdatedAt: 1778018078000,
      },
      { merge: true },
    );
  });

  await assertSucceeds(
    setDoc(
      ref,
      {
        arsiv: true,
        debugMode: false,
        deletedPost: false,
        deletedPostTime: 0,
        flood: false,
        floodCount: 1,
        gizlendi: false,
        img: [],
        imgMap: [],
        isAd: false,
        ad: false,
        izBirakYayinTarihi: 1778018077478,
        konum: "",
        mainFlood: "",
        metin: "",
        scheduledAt: 0,
        sikayetEdildi: false,
        stabilized: false,
        stats: {
          commentCount: 0,
          likeCount: 0,
          reportedCount: 0,
          retryCount: 0,
          savedCount: 0,
          statsCount: 0,
        },
        tags: [],
        thumbnail: "",
        timeStamp: 1778018077478,
        userID: uid,
        authorNickname: "turqapp",
        authorDisplayName: "TurqApp",
        authorAvatarUrl: "",
        nickname: "turqapp",
        username: "turqapp",
        fullName: "TurqApp",
        displayName: "TurqApp",
        avatarUrl: "",
        rozet: "",
        video: "",
        isUploading: true,
        hlsStatus: "none",
        hlsMasterUrl: "",
        hlsUpdatedAt: 0,
        yorumMap: {
          visibility: 0,
        },
        reshareMap: {
          visibility: 0,
        },
        originalUserID: "",
        originalPostID: "",
        sourcePostID: "",
        sharedAsPost: false,
        quotedPost: false,
        quotedOriginalText: "",
        quotedSourceUserID: "",
        quotedSourceDisplayName: "",
        quotedSourceUsername: "",
        quotedSourceAvatarUrl: "",
      },
      { merge: true },
    ),
  );
});
