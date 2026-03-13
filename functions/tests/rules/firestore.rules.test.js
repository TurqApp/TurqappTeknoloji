const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const RULES_PATH = path.resolve(__dirname, "../../../firestore.rules");

let testEnv;
let assertFails;
let assertSucceeds;
let initializeTestEnvironment;
let doc;
let deleteDoc;
let getDoc;
let setDoc;
let updateDoc;

test.before(async () => {
  ({ initializeTestEnvironment, assertFails, assertSucceeds } = await import(
    "@firebase/rules-unit-testing"
  ));
  ({ doc, deleteDoc, getDoc, setDoc, updateDoc } = await import("firebase/firestore"));
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

test("users collection denies unauthenticated reads", async () => {
  const unauthCtx = testEnv.unauthenticatedContext();
  await assertFails(getDoc(doc(unauthCtx.firestore(), "users/some-user")));
});

test("users collection allows owner create/read for own document", async () => {
  const uid = "owner-user";
  const ownerCtx = testEnv.authenticatedContext(uid);
  const ownerDoc = doc(ownerCtx.firestore(), `users/${uid}`);

  await assertSucceeds(setDoc(ownerDoc, { firstName: "Turq" }));
  await assertSucceeds(getDoc(ownerDoc));
});

test("users collection blocks owner from writing moderation fields", async () => {
  const uid = "moderation-owner";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `users/${uid}`), {
      firstName: "Owner",
      isBanned: false,
    });
  });

  const ownerCtx = testEnv.authenticatedContext(uid);
  await assertFails(
    updateDoc(doc(ownerCtx.firestore(), `users/${uid}`), { isBanned: true }),
  );
});

test("posts collection allows admin to update another user's post", async () => {
  const ownerUid = "post-owner";
  const adminUid = "admin-user";
  const postId = "foreign-post";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "ilk metin",
      deletedPost: false,
      deletedPostTime: 0,
    });
  });

  const adminCtx = testEnv.authenticatedContext(adminUid, { admin: true });
  await assertSucceeds(
    updateDoc(doc(adminCtx.firestore(), `Posts/${postId}`), {
      metin: "admin duzenledi",
    }),
  );
});

test("posts collection allows admin to delete another user's post", async () => {
  const ownerUid = "post-owner";
  const adminUid = "admin-user";
  const postId = "foreign-post-delete";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "ilk metin",
      deletedPost: false,
      deletedPostTime: 0,
    });
  });

  const adminCtx = testEnv.authenticatedContext(adminUid, { admin: true });
  await assertSucceeds(deleteDoc(doc(adminCtx.firestore(), `Posts/${postId}`)));
});

test("posts collection blocks non-owner non-admin from updating another user's post", async () => {
  const ownerUid = "post-owner";
  const otherUid = "other-user";
  const postId = "foreign-post-blocked";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "ilk metin",
      deletedPost: false,
      deletedPostTime: 0,
    });
  });

  const otherCtx = testEnv.authenticatedContext(otherUid);
  await assertFails(
    updateDoc(doc(otherCtx.firestore(), `Posts/${postId}`), {
      metin: "yetkisiz degisim",
    }),
  );
});

test("posts likes allow self-scoped interaction payload", async () => {
  const ownerUid = "post-owner-like";
  const likerUid = "post-liker";
  const postId = "post-like-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "like test",
    });
  });

  const likerCtx = testEnv.authenticatedContext(likerUid);
  await assertSucceeds(
    setDoc(doc(likerCtx.firestore(), `Posts/${postId}/likes/${likerUid}`), {
      userID: likerUid,
      timeStamp: Date.now(),
    }),
  );
});

test("posts likes block spoofed payload", async () => {
  const ownerUid = "post-owner-like-block";
  const likerUid = "post-liker-block";
  const postId = "post-like-block";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "like block test",
    });
  });

  const likerCtx = testEnv.authenticatedContext(likerUid);
  await assertFails(
    setDoc(doc(likerCtx.firestore(), `Posts/${postId}/likes/${likerUid}`), {
      userID: "someone-else",
      timeStamp: Date.now(),
    }),
  );
});

test("posts viewers allow legacy random-doc payload for self", async () => {
  const ownerUid = "post-owner-view";
  const viewerUid = "post-viewer";
  const postId = "post-view-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "viewer test",
    });
  });

  const viewerCtx = testEnv.authenticatedContext(viewerUid);
  await assertSucceeds(
    setDoc(doc(viewerCtx.firestore(), `Posts/${postId}/viewers/random-doc`), {
      userID: viewerUid,
      timeStamp: Date.now(),
    }),
  );
});

test("posts viewers block spoofed user id on random-doc payload", async () => {
  const ownerUid = "post-owner-view-block";
  const viewerUid = "post-viewer-block";
  const postId = "post-view-block";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "viewer block test",
    });
  });

  const viewerCtx = testEnv.authenticatedContext(viewerUid);
  await assertFails(
    setDoc(doc(viewerCtx.firestore(), `Posts/${postId}/viewers/random-doc`), {
      userID: "different-user",
      timeStamp: Date.now(),
    }),
  );
});

test("posts reshares allow quote metadata payload", async () => {
  const ownerUid = "post-owner-reshare";
  const sharerUid = "post-sharer";
  const postId = "post-reshare-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "reshare test",
    });
  });

  const sharerCtx = testEnv.authenticatedContext(sharerUid);
  await assertSucceeds(
    setDoc(doc(sharerCtx.firestore(), `Posts/${postId}/reshares/${sharerUid}`), {
      userID: sharerUid,
      timeStamp: Date.now(),
      originalUserID: ownerUid,
      originalPostID: postId,
      sharedPostID: "shared-post-1",
      quotedPost: true,
    }),
  );
});

test("stories likes allow self like payload", async () => {
  const ownerUid = "story-owner";
  const likerUid = "story-liker";
  const storyId = "story-like-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `stories/${storyId}`), {
      userId: ownerUid,
      createdDate: Date.now(),
    });
  });

  const likerCtx = testEnv.authenticatedContext(likerUid);
  await assertSucceeds(
    setDoc(doc(likerCtx.firestore(), `stories/${storyId}/likes/${likerUid}`), {
      timeStamp: Date.now(),
    }),
  );
});

test("stories viewers allow self viewer payload", async () => {
  const ownerUid = "story-owner-view";
  const viewerUid = "story-viewer";
  const storyId = "story-view-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `stories/${storyId}`), {
      userId: ownerUid,
      createdDate: Date.now(),
    });
  });

  const viewerCtx = testEnv.authenticatedContext(viewerUid);
  await assertSucceeds(
    setDoc(doc(viewerCtx.firestore(), `stories/${storyId}/Viewers/${viewerUid}`), {
      timeStamp: Date.now(),
    }),
  );
});

test("reports collection allows authenticated complaint payload", async () => {
  const uid = "reporter-user";
  const ctx = testEnv.authenticatedContext(uid);

  await assertSucceeds(
    setDoc(doc(ctx.firestore(), "reports/complaint-1"), {
      postID: "question-123",
      sikayetDesc: "Bu soru icin sikayet aciklamasi",
      sikayetTitle: "Sorunun yanlis oldugunu dusunuyorum.",
      timeStamp: Date.now(),
      userID: uid,
      yorumID: "",
    }),
  );
});

test("reports collection blocks spoofed reporter user id", async () => {
  const ctx = testEnv.authenticatedContext("real-user");

  await assertFails(
    setDoc(doc(ctx.firestore(), "reports/complaint-2"), {
      postID: "question-456",
      sikayetDesc: "Yetkisiz rapor",
      sikayetTitle: "Sikayet",
      timeStamp: Date.now(),
      userID: "different-user",
      yorumID: "",
    }),
  );
});

test("reports collection blocks unexpected complaint fields", async () => {
  const uid = "reporter-extra";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    setDoc(doc(ctx.firestore(), "reports/complaint-3"), {
      postID: "question-789",
      sikayetDesc: "Ek alan deneniyor",
      sikayetTitle: "Sikayet",
      timeStamp: Date.now(),
      userID: uid,
      yorumID: "",
      admin: true,
    }),
  );
});

test("phoneAccounts allows canonical self create payload", async () => {
  const uid = "phone-owner";
  const ctx = testEnv.authenticatedContext(uid);

  await assertSucceeds(
    setDoc(doc(ctx.firestore(), "phoneAccounts/5551112233"), {
      phone: "5551112233",
      count: 1,
      limit: 5,
      accounts: [uid],
      createdDate: Date.now(),
      lastCreatedAt: Date.now(),
    }),
  );
});

test("phoneAccounts blocks unexpected fields on create", async () => {
  const uid = "phone-owner-extra";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    setDoc(doc(ctx.firestore(), "phoneAccounts/5551112244"), {
      phone: "5551112244",
      count: 1,
      limit: 5,
      accounts: [uid],
      createdDate: Date.now(),
      lastCreatedAt: Date.now(),
      role: "admin",
    }),
  );
});

test("phoneAccounts allows self removal update without changing phone", async () => {
  const uid = "phone-owner-delete";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "phoneAccounts/5551112255"), {
      phone: "5551112255",
      count: 1,
      limit: 5,
      accounts: [uid],
      createdDate: Date.now() - 1000,
      lastCreatedAt: Date.now() - 1000,
    });
  });

  const ctx = testEnv.authenticatedContext(uid);
  await assertSucceeds(
    updateDoc(doc(ctx.firestore(), "phoneAccounts/5551112255"), {
      count: 0,
      accounts: [],
      lastUpdatedAt: Date.now(),
    }),
  );
});

test("phoneAccounts blocks phone mutation on update", async () => {
  const uid = "phone-owner-mutate";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "phoneAccounts/5551112266"), {
      phone: "5551112266",
      count: 1,
      limit: 5,
      accounts: [uid],
      createdDate: Date.now() - 1000,
      lastCreatedAt: Date.now() - 1000,
    });
  });

  const ctx = testEnv.authenticatedContext(uid);
  await assertFails(
    updateDoc(doc(ctx.firestore(), "phoneAccounts/5551112266"), {
      phone: "5550000000",
      count: 0,
      accounts: [],
      lastUpdatedAt: Date.now(),
    }),
  );
});

test("users_usernames legacy reservation path is disabled", async () => {
  const uid = "legacy-username-user";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    setDoc(doc(ctx.firestore(), "users_usernames/testuser"), {
      uid,
    }),
  );
});

test("Hashtags legacy collection rejects client writes", async () => {
  const uid = "legacy-hashtag-user";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    setDoc(doc(ctx.firestore(), "Hashtags/test-tag"), {
      value: "#test",
    }),
  );
});

test("HashTags legacy collection rejects client writes", async () => {
  const uid = "legacy-hashtag-user-2";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    setDoc(doc(ctx.firestore(), "HashTags/test-tag"), {
      value: "#test",
    }),
  );
});
