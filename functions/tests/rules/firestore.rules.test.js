const fs = require("node:fs");
const path = require("node:path");
const test = require("node:test");

const RULES_PATH = path.resolve(__dirname, "../../../firestore.rules");

let testEnv;
let assertFails;
let assertSucceeds;
let initializeTestEnvironment;
let addDoc;
let collection;
let doc;
let deleteDoc;
let getDoc;
let setDoc;
let updateDoc;

test.before(async () => {
  ({ initializeTestEnvironment, assertFails, assertSucceeds } = await import(
    "@firebase/rules-unit-testing"
  ));
  ({ addDoc, collection, doc, deleteDoc, getDoc, setDoc, updateDoc } = await import("firebase/firestore"));
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

test("posts collection allows owner to edit content without touching counters", async () => {
  const ownerUid = "post-owner-edit";
  const postId = "post-owner-edit-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "ilk metin",
      stats: {
        likeCount: 1,
        commentCount: 2,
        savedCount: 3,
        retryCount: 4,
        statsCount: 5,
        reportedCount: 0,
      },
    });
  });

  const ownerCtx = testEnv.authenticatedContext(ownerUid);
  await assertSucceeds(
    updateDoc(doc(ownerCtx.firestore(), `Posts/${postId}`), {
      metin: "duzenlenmis metin",
    }),
  );
});

test("posts collection blocks owner from arbitrarily inflating counters", async () => {
  const ownerUid = "post-owner-counter";
  const postId = "post-owner-counter-block";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "ilk metin",
      stats: {
        likeCount: 1,
        commentCount: 0,
        savedCount: 0,
        retryCount: 0,
        statsCount: 0,
        reportedCount: 0,
      },
    });
  });

  const ownerCtx = testEnv.authenticatedContext(ownerUid);
  await assertFails(
    updateDoc(doc(ownerCtx.firestore(), `Posts/${postId}`), {
      "stats.likeCount": 99,
    }),
  );
});

test("posts collection allows single-step like counter increments", async () => {
  const ownerUid = "post-owner-like-count";
  const actorUid = "post-actor-like-count";
  const postId = "post-like-count-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "like count test",
      stats: {
        likeCount: 1,
        commentCount: 0,
        savedCount: 0,
        retryCount: 0,
        statsCount: 0,
        reportedCount: 0,
      },
    });
  });

  const actorCtx = testEnv.authenticatedContext(actorUid);
  await assertSucceeds(
    updateDoc(doc(actorCtx.firestore(), `Posts/${postId}`), {
      "stats.likeCount": 2,
    }),
  );
});

test("posts collection blocks multi-step like counter jumps", async () => {
  const ownerUid = "post-owner-like-jump";
  const actorUid = "post-actor-like-jump";
  const postId = "post-like-jump-block";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "like jump test",
      stats: {
        likeCount: 1,
        commentCount: 0,
        savedCount: 0,
        retryCount: 0,
        statsCount: 0,
        reportedCount: 0,
      },
    });
  });

  const actorCtx = testEnv.authenticatedContext(actorUid);
  await assertFails(
    updateDoc(doc(actorCtx.firestore(), `Posts/${postId}`), {
      "stats.likeCount": 4,
    }),
  );
});

test("posts collection allows single-step comment counter decrements", async () => {
  const ownerUid = "post-owner-comment-count";
  const actorUid = "post-actor-comment-count";
  const postId = "post-comment-count-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "comment count test",
      stats: {
        likeCount: 0,
        commentCount: 3,
        savedCount: 0,
        retryCount: 0,
        statsCount: 0,
        reportedCount: 0,
      },
    });
  });

  const actorCtx = testEnv.authenticatedContext(actorUid);
  await assertSucceeds(
    updateDoc(doc(actorCtx.firestore(), `Posts/${postId}`), {
      "stats.commentCount": 2,
    }),
  );
});

test("posts collection blocks multiple stat keys in a single client update", async () => {
  const ownerUid = "post-owner-multi-stats";
  const actorUid = "post-actor-multi-stats";
  const postId = "post-multi-stats-block";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "multi stats test",
      stats: {
        likeCount: 1,
        commentCount: 1,
        savedCount: 0,
        retryCount: 0,
        statsCount: 0,
        reportedCount: 0,
      },
    });
  });

  const actorCtx = testEnv.authenticatedContext(actorUid);
  await assertFails(
    updateDoc(doc(actorCtx.firestore(), `Posts/${postId}`), {
      "stats.likeCount": 2,
      "stats.savedCount": 1,
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

test("posts comments allow owner-scoped canonical payload", async () => {
  const ownerUid = "post-owner-comment";
  const commenterUid = "post-commenter";
  const postId = "post-comment-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "comment test",
    });
  });

  const commenterCtx = testEnv.authenticatedContext(commenterUid);
  await assertSucceeds(
    setDoc(doc(commenterCtx.firestore(), `Posts/${postId}/comments/comment-1`), {
      likes: [],
      text: "Merhaba",
      imgs: [],
      videos: [],
      timeStamp: Date.now(),
      userID: commenterUid,
      edited: false,
      editTimestamp: 0,
      deleted: false,
      deletedTimeStamp: 0,
      hasReplies: false,
      repliesCount: 0,
    }),
  );
});

test("posts comments block spoofed owner and unexpected fields", async () => {
  const ownerUid = "post-owner-comment-block";
  const commenterUid = "post-commenter-block";
  const postId = "post-comment-block";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "comment block test",
    });
  });

  const commenterCtx = testEnv.authenticatedContext(commenterUid);
  await assertFails(
    setDoc(doc(commenterCtx.firestore(), `Posts/${postId}/comments/comment-1`), {
      likes: [],
      text: "Yetkisiz",
      imgs: [],
      videos: [],
      timeStamp: Date.now(),
      userID: ownerUid,
      edited: false,
      editTimestamp: 0,
      deleted: false,
      deletedTimeStamp: 0,
      hasReplies: false,
      repliesCount: 0,
      adminOnly: true,
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

test("posts izBirakSubscribers allow self-scoped subscription payload", async () => {
  const ownerUid = "post-owner-izbirak";
  const subscriberUid = "post-subscriber-izbirak";
  const postId = "post-izbirak-subscribe-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "iz birak test",
    });
  });

  const subscriberCtx = testEnv.authenticatedContext(subscriberUid);
  await assertSucceeds(
    setDoc(
      doc(
        subscriberCtx.firestore(),
        `Posts/${postId}/izBirakSubscribers/${subscriberUid}`,
      ),
      {
        userID: subscriberUid,
        timeStamp: Date.now(),
      },
    ),
  );
});

test("posts izBirakSubscribers block spoofed subscription payload", async () => {
  const ownerUid = "post-owner-izbirak-block";
  const subscriberUid = "post-subscriber-izbirak-block";
  const postId = "post-izbirak-subscribe-block";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `Posts/${postId}`), {
      userID: ownerUid,
      metin: "iz birak block test",
    });
  });

  const subscriberCtx = testEnv.authenticatedContext(subscriberUid);
  await assertFails(
    setDoc(
      doc(
        subscriberCtx.firestore(),
        `Posts/${postId}/izBirakSubscribers/${subscriberUid}`,
      ),
      {
        userID: ownerUid,
        timeStamp: Date.now(),
      },
    ),
  );
});

test("stories collection allows owner-scoped create", async () => {
  const ownerUid = "story-owner-create";
  const storyId = "story-create-ok";
  const ownerCtx = testEnv.authenticatedContext(ownerUid);

  await assertSucceeds(
    setDoc(doc(ownerCtx.firestore(), `stories/${storyId}`), {
      userId: ownerUid,
      createdDate: Date.now(),
      deleted: false,
      deletedAt: 0,
    }),
  );
});

test("stories collection blocks spoofed owner on create", async () => {
  const ownerUid = "story-owner-create-block";
  const storyId = "story-create-block";
  const ownerCtx = testEnv.authenticatedContext(ownerUid);

  await assertFails(
    setDoc(doc(ownerCtx.firestore(), `stories/${storyId}`), {
      userId: "different-user",
      createdDate: Date.now(),
    }),
  );
});

test("stories collection allows owner lifecycle updates only", async () => {
  const ownerUid = "story-owner-update";
  const storyId = "story-update-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `stories/${storyId}`), {
      userId: ownerUid,
      createdDate: Date.now(),
      deleted: false,
      deletedAt: 0,
    });
  });

  const ownerCtx = testEnv.authenticatedContext(ownerUid);
  await assertSucceeds(
    updateDoc(doc(ownerCtx.firestore(), `stories/${storyId}`), {
      deleted: true,
      deletedAt: Date.now(),
      deleteReason: "manual",
    }),
  );
});

test("stories collection blocks arbitrary owner content updates", async () => {
  const ownerUid = "story-owner-update-block";
  const storyId = "story-update-block";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `stories/${storyId}`), {
      userId: ownerUid,
      createdDate: Date.now(),
      deleted: false,
      deletedAt: 0,
    });
  });

  const ownerCtx = testEnv.authenticatedContext(ownerUid);
  await assertFails(
    updateDoc(doc(ownerCtx.firestore(), `stories/${storyId}`), {
      createdDate: Date.now() + 1000,
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

test("stories comments allow canonical payload", async () => {
  const ownerUid = "story-owner-comment";
  const commenterUid = "story-commenter";
  const storyId = "story-comment-ok";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `stories/${storyId}`), {
      userId: ownerUid,
      createdDate: Date.now(),
    });
  });

  const commenterCtx = testEnv.authenticatedContext(commenterUid);
  await assertSucceeds(
    addDoc(collection(commenterCtx.firestore(), `stories/${storyId}/Yorumlar`), {
      userID: commenterUid,
      metin: "Story yorumu",
      timeStamp: Date.now(),
      gif: "",
    }),
  );
});

test("stories comments block spoofed payload", async () => {
  const ownerUid = "story-owner-comment-block";
  const commenterUid = "story-commenter-block";
  const storyId = "story-comment-block";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `stories/${storyId}`), {
      userId: ownerUid,
      createdDate: Date.now(),
    });
  });

  const commenterCtx = testEnv.authenticatedContext(commenterUid);
  await assertFails(
    addDoc(collection(commenterCtx.firestore(), `stories/${storyId}/Yorumlar`), {
      userID: ownerUid,
      metin: "Spoofed story yorumu",
      timeStamp: Date.now(),
      gif: "",
      extra: true,
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

test("CikmisSorular allows admin-managed writes only", async () => {
  const adminCtx = testEnv.authenticatedContext("education-admin", { admin: true });
  const userCtx = testEnv.authenticatedContext("education-user");

  await assertSucceeds(
    setDoc(doc(adminCtx.firestore(), "CikmisSorular/cikmis-1"), {
      anaBaslik: "TYT",
      sinavTuru: "Turkce",
    }),
  );
  await assertFails(
    setDoc(doc(userCtx.firestore(), "CikmisSorular/cikmis-2"), {
      anaBaslik: "AYT",
      sinavTuru: "Matematik",
    }),
  );
});

test("questions allows admin-managed root writes only", async () => {
  const adminCtx = testEnv.authenticatedContext("question-admin", { admin: true });
  const userCtx = testEnv.authenticatedContext("question-user");

  await assertSucceeds(
    setDoc(doc(adminCtx.firestore(), "questions", "question-root-1"), {
      anaBaslik: "TYT",
      sinavTuru: "Turkce",
      sira: 1,
    }),
  );
  await assertFails(
    setDoc(doc(userCtx.firestore(), "questions", "question-root-2"), {
      anaBaslik: "AYT",
      sinavTuru: "Matematik",
      sira: 2,
    }),
  );
});

test("questions subcollections allow admin writes and block non-admin writes", async () => {
  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "questions", "question-root-3"), {
      anaBaslik: "TYT",
      sinavTuru: "Turkce",
      sira: 3,
    });
  });

  const adminCtx = testEnv.authenticatedContext("question-admin-sub", { admin: true });
  const userCtx = testEnv.authenticatedContext("question-user-sub");

  await assertSucceeds(
    setDoc(doc(adminCtx.firestore(), "questions", "question-root-3", "questions", "item-1"), {
      soru: "Soru 1",
      dogruCevap: "A",
    }),
  );
  await assertFails(
    setDoc(doc(userCtx.firestore(), "questions", "question-root-3", "Sorular", "item-2"), {
      soru: "Yetkisiz soru",
      dogruCevap: "B",
    }),
  );
});

test("questionsAnswers allows owner-scoped canonical payload", async () => {
  const uid = "questions-answer-owner";
  const ctx = testEnv.authenticatedContext(uid);

  await assertSucceeds(
    addDoc(collection(ctx.firestore(), "questionsAnswers"), {
      cevaplar: ["A", "B", "C"],
      dogruCevaplar: ["A", "D", "C"],
      timeStamp: Date.now(),
      anaBaslik: "TYT",
      sinavTuru: "Turkce",
      yil: "2025",
      baslik2: "Genel",
      baslik3: "",
      cikmisSoruID: "cikmis-1",
      userID: uid,
    }),
  );
});

test("questionsAnswers blocks spoofed owner payload", async () => {
  const uid = "questions-answer-owner-block";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    addDoc(collection(ctx.firestore(), "questionsAnswers"), {
      cevaplar: ["A"],
      dogruCevaplar: ["A"],
      timeStamp: Date.now(),
      anaBaslik: "TYT",
      sinavTuru: "Turkce",
      yil: "2025",
      baslik2: "Genel",
      baslik3: "",
      cikmisSoruID: "cikmis-2",
      userID: "different-user",
      extra: true,
    }),
  );
});

test("users KitapcikCevaplari allows owner-scoped canonical payload", async () => {
  const uid = "booklet-answer-owner";
  const ctx = testEnv.authenticatedContext(uid);

  await assertSucceeds(
    setDoc(doc(ctx.firestore(), "users", uid, "KitapcikCevaplari", "result-1"), {
      timeStamp: Date.now(),
      kitapcikID: "booklet-1",
      baslik: "Deneme 1",
      cevaplar: ["A", "B", ""],
      dogruCevaplar: ["A", "D", "C"],
      dogru: 1,
      yanlis: 1,
      bos: 1,
      puan: 33.3,
      net: 0.75,
    }),
  );
});

test("users KitapcikCevaplari blocks spoofed and malformed payload", async () => {
  const uid = "booklet-answer-owner-block";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    setDoc(doc(ctx.firestore(), "users", uid, "KitapcikCevaplari", "result-1"), {
      timeStamp: Date.now(),
      kitapcikID: "booklet-2",
      baslik: "Deneme 2",
      cevaplar: ["A"],
      dogruCevaplar: ["A", "B"],
      dogru: 1,
      yanlis: 0,
      bos: 0,
      puan: 100,
      net: 1,
      userID: "different-user",
    }),
  );
});

test("KitapcikCevaplari legacy root path rejects client writes", async () => {
  const uid = "booklet-answer-legacy";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    setDoc(doc(ctx.firestore(), "KitapcikCevaplari/legacy-result-1"), {
      timeStamp: Date.now(),
      kitapcikID: "legacy-booklet",
      baslik: "Legacy Deneme",
      cevaplar: ["A"],
      dogruCevaplar: ["A"],
      dogru: 1,
      yanlis: 0,
      bos: 0,
      puan: 100,
      net: 1,
      userID: uid,
    }),
  );
});

test("optikForm allows owner-scoped canonical payload", async () => {
  const uid = "optik-owner";
  const ctx = testEnv.authenticatedContext(uid);

  await assertSucceeds(
    setDoc(doc(ctx.firestore(), "optikForm/form-1"), {
      max: 4,
      cevaplar: ["A", "B", "C", "D"],
      name: "Deneme Formu",
      userID: uid,
      baslangic: Date.now(),
      bitis: Date.now() + 60000,
      kisitlama: false,
    }),
  );
});

test("optikForm blocks spoofed owner payload", async () => {
  const uid = "optik-owner-block";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    setDoc(doc(ctx.firestore(), "optikForm/form-2"), {
      max: 4,
      cevaplar: ["A", "B", "C", "D"],
      name: "Deneme Formu",
      userID: "different-user",
      baslangic: Date.now(),
      bitis: Date.now() + 60000,
      kisitlama: false,
      unexpected: true,
    }),
  );
});

test("optikForm answers allow owner create and update", async () => {
  const uid = "optik-answer-owner";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "optikForm/form-answers"), {
      max: 4,
      cevaplar: ["A", "B", "C", "D"],
      name: "Form",
      userID: uid,
      baslangic: Date.now(),
      bitis: Date.now() + 60000,
      kisitlama: false,
    });
  });

  const ctx = testEnv.authenticatedContext(uid);
  const answerRef = doc(
    ctx.firestore(),
    "optikForm",
    "form-answers",
    "Yanitlar",
    "optik-answer-owner",
  );
  await assertSucceeds(
    setDoc(answerRef, {
      timeStamp: Date.now(),
      cevaplar: ["", "", "", ""],
    }),
  );
  await assertSucceeds(
    updateDoc(answerRef, {
      timeStamp: Date.now(),
      cevaplar: ["A", "B", "", "D"],
      ogrenciNo: "123",
      fullName: "Test User",
    }),
  );
});

test("optikForm answers block other users", async () => {
  const ownerUid = "optik-answer-owner-block";
  const attackerUid = "optik-answer-attacker";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "optikForm/form-answers-block"), {
      max: 4,
      cevaplar: ["A", "B", "C", "D"],
      name: "Form",
      userID: ownerUid,
      baslangic: Date.now(),
      bitis: Date.now() + 60000,
      kisitlama: false,
    });
  });

  const attackerCtx = testEnv.authenticatedContext(attackerUid);
  await assertFails(
    setDoc(doc(attackerCtx.firestore(), "optikForm/form-answers-block/Yanitlar/optik-answer-owner-block"), {
      timeStamp: Date.now(),
      cevaplar: ["A"],
    }),
  );
});

test("books allows canonical owner create payload", async () => {
  const uid = "book-owner";
  const ctx = testEnv.authenticatedContext(uid);

  await assertSucceeds(
    setDoc(doc(ctx.firestore(), "books/book-1"), {
      basimTarihi: "2026",
      baslik: "Deneme Kitabi",
      cover: "",
      dil: "Turkce",
      sinavTuru: "TYT",
      timeStamp: Date.now(),
      yayinEvi: "Turq",
      userID: uid,
      viewCount: 0,
    }),
  );
});

test("books blocks spoofed owner and unexpected fields on create", async () => {
  const uid = "book-owner-block";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    setDoc(doc(ctx.firestore(), "books/book-2"), {
      basimTarihi: "2026",
      baslik: "Deneme Kitabi",
      cover: "",
      dil: "Turkce",
      sinavTuru: "TYT",
      timeStamp: Date.now(),
      yayinEvi: "Turq",
      userID: "different-user",
      viewCount: 0,
      role: "admin",
    }),
  );
});

test("books CevapAnahtarlari allows canonical owner payload and delete", async () => {
  const uid = "book-answer-owner";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "books", "book-answer-1"), {
      basimTarihi: "2026",
      baslik: "Deneme Kitabi",
      cover: "",
      dil: "Turkce",
      sinavTuru: "TYT",
      timeStamp: Date.now(),
      yayinEvi: "Turq",
      userID: uid,
      viewCount: 0,
    });
  });

  const ctx = testEnv.authenticatedContext(uid);
  const answerRef = doc(
    ctx.firestore(),
    "books",
    "book-answer-1",
    "CevapAnahtarlari",
    "key-1",
  );
  await assertSucceeds(
    setDoc(answerRef, {
      baslik: "Deneme 1",
      sira: 1,
      dogruCevaplar: ["A", "B", "C"],
    }),
  );
  await assertSucceeds(deleteDoc(answerRef));
});

test("books CevapAnahtarlari blocks spoofed payload", async () => {
  const ownerUid = "book-answer-owner-block";
  const attackerUid = "book-answer-attacker";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), "books", "book-answer-2"), {
      basimTarihi: "2026",
      baslik: "Deneme Kitabi",
      cover: "",
      dil: "Turkce",
      sinavTuru: "TYT",
      timeStamp: Date.now(),
      yayinEvi: "Turq",
      userID: ownerUid,
      viewCount: 0,
    });
  });

  const attackerCtx = testEnv.authenticatedContext(attackerUid);
  await assertFails(
    setDoc(doc(
      attackerCtx.firestore(),
      "books",
      "book-answer-2",
      "CevapAnahtarlari",
      "key-1",
    ), {
      baslik: "Deneme 1",
      sira: 1,
      dogruCevaplar: ["A", "B"],
      adminOnly: true,
    }),
  );
});

test("Sorular legacy root path rejects client writes", async () => {
  const uid = "legacy-question-owner";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    setDoc(doc(ctx.firestore(), "Sorular/legacy-question-1"), {
      userID: uid,
      soru: "Legacy soru",
      dogruCevap: "A",
    }),
  );
});

test("SinaviBitenler legacy root path rejects client writes", async () => {
  const uid = "legacy-exam-finisher";
  const ctx = testEnv.authenticatedContext(uid);

  await assertFails(
    setDoc(doc(ctx.firestore(), "SinaviBitenler/legacy-finish-1"), {
      userID: uid,
      timeStamp: Date.now(),
    }),
  );
});

test("practiceExams SinaviBitenler allows canonical owner payload", async () => {
  const ownerUid = "practice-exam-owner";
  const finisherUid = "practice-exam-finisher";
  const examId = "practice-exam-1";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `practiceExams/${examId}`), {
      userID: ownerUid,
      title: "Exam",
    });
  });

  const finisherCtx = testEnv.authenticatedContext(finisherUid);
  await assertSucceeds(
    setDoc(doc(finisherCtx.firestore(), `practiceExams/${examId}/SinaviBitenler/finish-1`), {
      userID: finisherUid,
      timeStamp: Date.now(),
    }),
  );
});

test("practiceExams SinaviBitenler blocks spoofed payload", async () => {
  const ownerUid = "practice-exam-owner-block";
  const finisherUid = "practice-exam-finisher-block";
  const examId = "practice-exam-2";

  await testEnv.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), `practiceExams/${examId}`), {
      userID: ownerUid,
      title: "Exam",
    });
  });

  const finisherCtx = testEnv.authenticatedContext(finisherUid);
  await assertFails(
    setDoc(doc(finisherCtx.firestore(), `practiceExams/${examId}/SinaviBitenler/finish-1`), {
      userID: ownerUid,
      timeStamp: Date.now(),
      extra: true,
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
