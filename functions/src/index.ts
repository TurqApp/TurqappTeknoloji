// Cloud Functions templates for story TTL and deletion archival
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();
const db = admin.firestore();

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 📸 IMAGE THUMBNAILS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// export { generateThumbnails } from "./thumbnails"; // ⏸️ Temporarily disabled (sharp build issue)

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🎬 HLS VIDEO TRANSCODE
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
export { onVideoUpload } from "./hlsTranscode";
export * from "./04_tagSettings";
export * from "./14_typesensePosts";
export * from "./15_typesenseUsersTags";
export * from "./16_tagMaintenance";

// SCHEDULED CLEANUP: Move expired (older than 24h) stories to DeletedStories and delete from Stories
export const cleanupExpiredStories = functions.pubsub
  .schedule("every 60 minutes")
  .onRun(async () => {
    const now = Date.now();
    const cutoff = now - 24 * 60 * 60 * 1000; // 24h in ms

    const snap = await db
      .collection("stories")
      .where("createdAt", "<=", cutoff)
      .limit(500)
      .get();

    const batch = db.batch();
    for (const doc of snap.docs) {
      try {
        const data = doc.data();
        const userId: string = data.userId;
        const archiveRef = db
          .collection("users")
          .doc(userId)
          .collection("DeletedStories")
          .doc();
        batch.set(archiveRef, {
          storyId: doc.id,
          deletedAt: now,
          reason: "expired_cf",
          userId: userId,
          createdAtOriginal: data.createdAt ?? now,
          backgroundColor: data.backgroundColor ?? 0,
          musicUrl: data.musicUrl ?? "",
          elements: data.elements ?? [],
        });
        batch.delete(doc.ref);
      } catch (e) {
        console.error("cleanupExpiredStories error", e);
      }
    }
    await batch.commit();
    return null;
  });

// FIRESTORE TRIGGER: When a story is deleted without client-side archival, archive it.
// Note: v2 onDocumentDeleted provides the old data; here we simulate with onDelete + data in value before delete.
export const archiveOnStoryDelete = functions.firestore
  .document("stories/{storyId}")
  .onDelete(async (snap, context) => {
    const data = snap.data();
    if (!data) return;
    try {
      const now = Date.now();
      const userId: string = data.userId;
      const archiveRef = db
        .collection("users")
        .doc(userId)
        .collection("DeletedStories")
        .doc();
      await archiveRef.set({
        storyId: context.params.storyId,
        deletedAt: now,
        reason: "onDelete_trigger",
        userId: userId,
        createdAtOriginal: data.createdAt ?? now,
        backgroundColor: data.backgroundColor ?? 0,
        musicUrl: data.musicUrl ?? "",
        elements: data.elements ?? [],
      });
    } catch (e) {
      console.error("archiveOnStoryDelete error", e);
    }
  });

// Helper: normalize phone to last 10 digits (TR mobile format in app)
const normalizePhone = (raw: string | undefined | null): string => {
  if (!raw) return "";
  const digits = String(raw).replace(/[^0-9]/g, "");
  if (digits.length >= 10) {
    return digits.substring(digits.length - 10);
  }
  return digits;
};

// SAFETY NET: Keep PhoneAccounts in sync when a user doc is deleted
export const onUserDocDelete = functions.firestore
  .document("users/{uid}")
  .onDelete(async (snap, context) => {
    const before = snap.data() as any | undefined;
    const uid = context.params.uid as string;
    const phone = normalizePhone(before?.phoneNumber);
    if (!phone) return;
    try {
      const ref = db.collection("PhoneAccounts").doc(phone);
      await db.runTransaction(async (tx) => {
        const doc = await tx.get(ref);
        if (!doc.exists) return;
        const data = doc.data() || {};
        const accounts: string[] = Array.isArray(data.accounts) ? data.accounts : [];
        const count = typeof data.count === "number" ? data.count : 0;
        const shouldDec = accounts.includes(uid) && count > 0;
        const update: any = {
          accounts: admin.firestore.FieldValue.arrayRemove(uid),
          lastUpdatedAt: Date.now(),
        };
        if (shouldDec) update.count = admin.firestore.FieldValue.increment(-1);
        tx.update(ref, update);
      });
    } catch (e) {
      console.error("onUserDocDelete error", e);
    }
  });

// SAFETY NET: Adjust counts if phone number changes on user doc
export const onUserDocUpdate = functions.firestore
  .document("users/{uid}")
  .onUpdate(async (change, context) => {
    const before = change.before.data() as any | undefined;
    const after = change.after.data() as any | undefined;
    const uid = context.params.uid as string;
    const oldPhone = normalizePhone(before?.phoneNumber);
    const newPhone = normalizePhone(after?.phoneNumber);
    if (!oldPhone && !newPhone) return;
    try {
      await db.runTransaction(async (tx) => {
        const now = Date.now();
        if (oldPhone && oldPhone !== newPhone) {
          const oldRef = db.collection("PhoneAccounts").doc(oldPhone);
          const oldDoc = await tx.get(oldRef);
          if (oldDoc.exists) {
            const odata = oldDoc.data() || {};
            const accounts: string[] = Array.isArray(odata.accounts) ? odata.accounts : [];
            const count = typeof odata.count === "number" ? odata.count : 0;
            const shouldDec = accounts.includes(uid) && count > 0;
            const update: any = {
              accounts: admin.firestore.FieldValue.arrayRemove(uid),
              lastUpdatedAt: now,
            };
            if (shouldDec) update.count = admin.firestore.FieldValue.increment(-1);
            tx.update(oldRef, update);
          }
        }

        if (newPhone && oldPhone !== newPhone) {
          const newRef = db.collection("PhoneAccounts").doc(newPhone);
          const newDoc = await tx.get(newRef);
          if (newDoc.exists) {
            const ndata = newDoc.data() || {};
            const accounts: string[] = Array.isArray(ndata.accounts) ? ndata.accounts : [];
            const shouldInc = !accounts.includes(uid);
            const update: any = {
              accounts: admin.firestore.FieldValue.arrayUnion(uid),
              lastUpdatedAt: now,
              lastCreatedAt: now,
            };
            if (shouldInc) update.count = admin.firestore.FieldValue.increment(1);
            tx.update(newRef, update);
          } else {
            tx.set(newRef, {
              phone: newPhone,
              count: 1,
              limit: 5,
              accounts: [uid],
              createdAt: now,
              lastCreatedAt: now,
            });
          }
        }
      });
    } catch (e) {
      console.error("onUserDocUpdate error", e);
    }
  });

// PUSH DISPATCHER: users/{uid}/notifications onCreate -> FCM
export const onUserNotificationCreate = functions.firestore
  .document("users/{uid}/notifications/{notificationId}")
  .onCreate(async (snap, context) => {
    try {
      const uid = context.params.uid as string;
      const data = (snap.data() || {}) as any;
      const type = String(data.type || "Posts");
      const fromUserID = String(data.fromUserID || "");
      const targetDocID = String(
        data.postID || data.chatID || data.userID || ""
      );
      const cfg = await _loadNotificationPushConfig();

      // Self-notification push göndermeyelim.
      if (fromUserID && fromUserID === uid) return;
      // Global veya tür bazlı kapalıysa push gönderme.
      if (!cfg.enabled || !_isNotificationTypeEnabled(type, cfg.types)) return;

      const userDoc = await db.collection("users").doc(uid).get();
      const userData = (userDoc.data() || {}) as any;
      const token = String(
        (userData.token as string) ||
          (userData.fcmToken as string) ||
          (userData.fcm_token as string) ||
          ""
      );
      if (!token) {
        console.log("onUserNotificationCreate skip:no_token", { uid, type });
        return;
      }

      const title = String(data.title || "TurqApp");
      const body = String(data.body || _notificationBodyFromType(type));

      await admin.messaging().send({
        token,
        notification: {
          title,
          body,
        },
        data: {
          docID: targetDocID,
          type,
        },
        android: {
          priority: "high",
          notification: {
            channelId: "high_importance_channel",
          },
        },
        apns: {
          headers: {
            "apns-priority": "10",
          },
          payload: {
            aps: {
              sound: "default",
            },
          },
        },
      });
      console.log("onUserNotificationCreate sent", { uid, type, tokenPresent: true });
    } catch (e) {
      console.error("onUserNotificationCreate error", e);
    }
  });

type PushTypeMap = {
  follow: boolean;
  comment: boolean;
  message: boolean;
  like: boolean;
  reshared_posts: boolean;
  shared_as_posts: boolean;
  posts: boolean;
};

const _defaultPushTypes: PushTypeMap = {
  follow: true,
  comment: true,
  message: true,
  like: true,
  reshared_posts: true,
  shared_as_posts: true,
  posts: true,
};

async function _loadNotificationPushConfig(): Promise<{
  enabled: boolean;
  types: PushTypeMap;
}> {
  try {
    const pushSnap = await db.doc("adminConfig/push").get();
    const pushData = (pushSnap.data() || {}) as any;

    // Primary schema (requested):
    // adminConfig/push => { enabled, follow, comment, message, like, reshared_posts, shared_as_posts, posts }
    const primaryEnabledRaw = pushData.enabled ?? true;
    const primaryTypesRaw = pushData as Record<string, unknown>;

    // Backward-compatible fallback schema:
    // adminConfig/service => { notifications: { enabled, types: {...} } } or legacy keys.
    const serviceSnap = await db.doc("adminConfig/service").get();
    const serviceData = (serviceSnap.data() || {}) as any;
    const notifications = (serviceData.notifications || {}) as any;
    const fallbackTypesRaw =
      (notifications.types || serviceData.notificationTypes || {}) as Record<string, unknown>;
    const fallbackEnabledRaw =
      notifications.enabled ?? serviceData.notificationsEnabled ?? true;

    const normalizeBool = (value: unknown, fallback: boolean): boolean => {
      if (typeof value === "boolean") return value;
      return fallback;
    };

    return {
      enabled: normalizeBool(primaryEnabledRaw, normalizeBool(fallbackEnabledRaw, true)),
      types: {
        follow: normalizeBool(
          primaryTypesRaw.follow,
          normalizeBool(fallbackTypesRaw.follow, _defaultPushTypes.follow)
        ),
        comment: normalizeBool(
          primaryTypesRaw.comment,
          normalizeBool(fallbackTypesRaw.comment, _defaultPushTypes.comment)
        ),
        message: normalizeBool(
          primaryTypesRaw.message,
          normalizeBool(fallbackTypesRaw.message, _defaultPushTypes.message)
        ),
        like: normalizeBool(
          primaryTypesRaw.like,
          normalizeBool(fallbackTypesRaw.like, _defaultPushTypes.like)
        ),
        reshared_posts: normalizeBool(
          primaryTypesRaw.reshared_posts,
          normalizeBool(
            fallbackTypesRaw.reshared_posts,
            _defaultPushTypes.reshared_posts
          )
        ),
        shared_as_posts: normalizeBool(
          primaryTypesRaw.shared_as_posts,
          normalizeBool(
            fallbackTypesRaw.shared_as_posts,
            _defaultPushTypes.shared_as_posts
          )
        ),
        posts: normalizeBool(
          primaryTypesRaw.posts,
          normalizeBool(fallbackTypesRaw.posts, _defaultPushTypes.posts)
        ),
      },
    };
  } catch (e) {
    console.error("_loadNotificationPushConfig error", e);
    return { enabled: true, types: _defaultPushTypes };
  }
}

function _isNotificationTypeEnabled(type: string, types: PushTypeMap): boolean {
  const t = String(type || "").toLowerCase();
  switch (t) {
    case "user":
    case "follow":
      return types.follow;
    case "comment":
      return types.comment;
    case "chat":
    case "message":
      return types.message;
    case "like":
      return types.like;
    case "reshared_posts":
      return types.reshared_posts;
    case "shared_as_posts":
      return types.shared_as_posts;
    case "posts":
      return types.posts;
    default:
      // Tanınmayan tipleri güvenli tarafta bırak: push açık
      return true;
  }
}

function _notificationBodyFromType(type: string): string {
  switch (type) {
    case "User":
    case "follow":
      return "seni takip etmeye başladı";
    case "Chat":
    case "message":
      return "sana mesaj gönderdi";
    case "Comment":
    case "comment":
      return "gönderine yorum yaptı";
    case "Posts":
    case "like":
    case "reshared_posts":
    case "shared_as_posts":
    default:
      return "gönderinle etkileşime geçti";
  }
}

// ADMIN UTILITY: Backfill PhoneAccounts from existing users
export const backfillPhoneAccounts = functions.https.onCall(async (data, context) => {
  // Require authenticated call; ideally require admin custom claim
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  }
  const isAdmin = (context.auth.token as any)?.admin === true;
  const providedSecret = typeof data?.secret === 'string' ? (data.secret as string) : '';
  const configuredSecret = (process.env.PHONE_BACKFILL_SECRET || (functions.config()?.limits?.backfill_secret as string | undefined) || '').toString();
  if (!isAdmin && (!configuredSecret || providedSecret !== configuredSecret)) {
    throw new functions.https.HttpsError('permission-denied', 'Admin or valid secret required');
  }

  const batchSize = Math.min(Number(data?.batchSize) || 500, 500);
  const startAfterId = typeof data?.startAfter === 'string' ? data.startAfter as string : undefined;

  let q = db.collection('users').orderBy(admin.firestore.FieldPath.documentId()).limit(batchSize);
  if (startAfterId) {
    const startSnap = await db.collection('users').doc(startAfterId).get();
    if (startSnap.exists) {
      q = db.collection('users')
        .orderBy(admin.firestore.FieldPath.documentId())
        .startAfter(startSnap.id)
        .limit(batchSize);
    }
  }

  const snap = await q.get();
  if (snap.empty) {
    return { done: true, processed: 0 };
  }

  const phoneMap = new Map<string, Set<string>>();
  for (const doc of snap.docs) {
    const data = doc.data() as any;
    const uid = doc.id;
    const phone = normalizePhone(data?.phoneNumber);
    if (!phone) continue;
    if (!phoneMap.has(phone)) phoneMap.set(phone, new Set());
    phoneMap.get(phone)!.add(uid);
  }

  const batch = db.batch();
  const now = Date.now();
  for (const [phone, uids] of phoneMap.entries()) {
    const ref = db.collection('PhoneAccounts').doc(phone);
    const arr = Array.from(uids);
    batch.set(ref, {
      phone,
      count: admin.firestore.FieldValue.increment(arr.length),
      limit: 5,
      accounts: admin.firestore.FieldValue.arrayUnion(...arr),
      lastUpdatedAt: now,
      lastCreatedAt: now,
      createdAt: now,
    }, { merge: true });
  }

  await batch.commit();

  const lastDoc = snap.docs[snap.docs.length - 1];
  return { done: false, processed: snap.size, lastId: lastDoc.id };
});

// ADMIN UTILITY: Backfill Posts with missing originalUserID/originalUserNickname (String '')
export const backfillPostsOriginalFields = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  }
  const isAdmin = (context.auth.token as any)?.admin === true;
  const providedSecret = typeof data?.secret === 'string' ? (data.secret as string) : '';
  const configuredSecret = (process.env.POSTS_BACKFILL_SECRET || (functions.config()?.limits?.posts_backfill_secret as string | undefined) || '').toString();
  if (!isAdmin && (!configuredSecret || providedSecret !== configuredSecret)) {
    throw new functions.https.HttpsError('permission-denied', 'Admin or valid secret required');
  }

  const batchSize = Math.min(Math.max(Number(data?.batchSize) || 500, 1), 500);
  const cursorTs = typeof data?.cursor?.timeStamp === 'number' ? (data.cursor.timeStamp as number) : undefined;
  const cursorId = typeof data?.cursor?.docId === 'string' ? (data.cursor.docId as string) : undefined;
  const onlyMissing = (data?.onlyMissing ?? true) !== false; // default true

  let q = db.collection('Posts')
    .orderBy('timeStamp', 'desc' as any)
    .orderBy(admin.firestore.FieldPath.documentId())
    .limit(batchSize);

  if (cursorTs !== undefined && cursorId) {
    q = db.collection('Posts')
      .orderBy('timeStamp', 'desc' as any)
      .orderBy(admin.firestore.FieldPath.documentId())
      .startAfter(cursorTs, cursorId)
      .limit(batchSize);
  }

  const snap = await q.get();
  if (snap.empty) {
    return { done: true, processed: 0, updated: 0, skipped: 0, failed: 0 };
  }

  let updated = 0;
  let skipped = 0;
  let failed = 0;

  const batch = db.batch();
  let writes = 0;

  for (const doc of snap.docs) {
    try {
      const data = doc.data() as any;
      const hasId = typeof data.originalUserID === 'string';
      const hasNick = typeof data.originalUserNickname === 'string';

      const patch: Record<string, string> = {};
      if (!hasId) patch.originalUserID = '';
      if (!hasNick) patch.originalUserNickname = '';

      if (Object.keys(patch).length === 0 && onlyMissing) {
        skipped += 1;
      } else if (Object.keys(patch).length > 0) {
        batch.update(doc.ref, patch);
        writes += 1;
        updated += 1;
      } else {
        skipped += 1;
      }
    } catch (e) {
      console.error('backfillPostsOriginalFields: error on', doc.id, e);
      failed += 1;
    }
  }

  if (writes > 0) {
    await batch.commit();
  }

  const last = snap.docs[snap.docs.length - 1];
  const lastData = last.data() as any;
  return {
    done: false,
    processed: snap.size,
    updated,
    skipped,
    failed,
    nextCursor: {
      timeStamp: typeof lastData.timeStamp === 'number' ? lastData.timeStamp : null,
      docId: last.id,
    },
  };
});

type PurgeDetail = {
  name: string;
  deletedDocuments: number;
};

type PurgeFailure = {
  name: string;
  message: string;
};

const STUDENT_PROTECTED_COLLECTIONS = new Set<string>([
  'TakipEdilenler',
  'Takipciler',
  'SosyalMedyaLinkleri',
]);

const countDocuments = async (
  collection: admin.firestore.CollectionReference,
): Promise<number> => {
  try {
    const snapshot = await collection.count().get();
    const total = snapshot.data().count;
    return typeof total === "number" ? total : 0;
  } catch (err) {
    console.error("countDocuments error", collection.path, err);
    // Fallback: iterate in batches of 500 (may be slower but guarantees correctness)
    let total = 0;
    let query: admin.firestore.Query = collection
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(500);
    // eslint-disable-next-line no-constant-condition
    while (true) {
      const batch = await query.get();
      if (batch.empty) break;
      total += batch.size;
      const last = batch.docs[batch.docs.length - 1];
      query = collection.orderBy(admin.firestore.FieldPath.documentId()).startAfter(last.id).limit(500);
    }
    return total;
  }
};

export const purgePostSubcollections = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "Authentication required");
  }

  const docPathRaw = typeof data?.docPath === "string" ? (data.docPath as string) : "";
  const docPath = docPathRaw.trim();

  if (!docPath || !/^posts\/[A-Za-z0-9_-]+$/.test(docPath)) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "docPath must be a posts/{docId} path",
    );
  }

  const docRef = db.doc(docPath);
  const docSnap = await docRef.get();
  if (!docSnap.exists) {
    return {
      ok: true,
      found: false,
      deletedSubcollections: [],
      totalDeletedDocuments: 0,
    };
  }

  try {
    const subcollections = await docRef.listCollections();
    if (subcollections.length === 0) {
      return {
        ok: true,
        found: true,
        deletedSubcollections: [],
        totalDeletedDocuments: 0,
      };
    }

    const details: PurgeDetail[] = [];
    let totalDeleted = 0;

    for (const subcollection of subcollections) {
      const deletedDocuments = await countDocuments(subcollection);
      await admin.firestore().recursiveDelete(subcollection);
      details.push({
        name: subcollection.id,
        deletedDocuments,
      });
      totalDeleted += deletedDocuments;
    }

    return {
      ok: true,
      found: true,
      deletedSubcollections: details,
      totalDeletedDocuments: totalDeleted,
    };
  } catch (error: any) {
    console.error("purgePostSubcollections error", docPath, error);
    throw new functions.https.HttpsError(
      "internal",
      error?.message ?? "Failed to purge subcollections",
      {
        docPath,
      },
    );
  }
});

export const purgeStudentSubcollections = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }

    const docPathRaw = typeof data?.docPath === 'string' ? (data.docPath as string) : '';
    const docPath = docPathRaw.trim();

    if (!docPath || !/^users\/[A-Za-z0-9_-]+$/.test(docPath)) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'docPath must be a users/{docId} path',
      );
    }

    const docRef = db.doc(docPath);
    const docSnap = await docRef.get();
    if (!docSnap.exists) {
      return {
        ok: true,
        found: false,
        docPath,
        deletedSubcollections: [] as PurgeDetail[],
        failedSubcollections: [] as PurgeFailure[],
        skippedCollections: [] as string[],
        totalDeletedDocuments: 0,
        totalCollections: 0,
      };
    }

    try {
      const subcollections = await docRef.listCollections();
      if (subcollections.length === 0) {
        return {
          ok: true,
          found: true,
          docPath,
          deletedSubcollections: [] as PurgeDetail[],
          failedSubcollections: [] as PurgeFailure[],
          skippedCollections: [] as string[],
          totalDeletedDocuments: 0,
          totalCollections: 0,
        };
      }

      const details: PurgeDetail[] = [];
      const failures: PurgeFailure[] = [];
      const skipped: string[] = [];
      let totalDeleted = 0;

      for (const subcollection of subcollections) {
        const name = subcollection.id;
        if (STUDENT_PROTECTED_COLLECTIONS.has(name)) {
          skipped.push(name);
          continue;
        }

        try {
          const deletedDocuments = await countDocuments(subcollection);
          if (deletedDocuments > 0) {
            await admin.firestore().recursiveDelete(subcollection);
          }
          details.push({
            name,
            deletedDocuments,
          });
          totalDeleted += deletedDocuments;
        } catch (err: any) {
          console.error('purgeStudentSubcollections error', docPath, name, err);
          failures.push({
            name,
            message: typeof err?.message === 'string' ? err.message : String(err),
          });
        }
      }

      return {
        ok: true,
        found: true,
        docPath,
        deletedSubcollections: details,
        failedSubcollections: failures,
        skippedCollections: skipped,
        totalDeletedDocuments: totalDeleted,
        totalCollections: subcollections.length,
        processedAt: admin.firestore.Timestamp.now().toMillis(),
      };
    } catch (err: any) {
      console.error('purgeStudentSubcollections fatal error', docPath, err);
      throw new functions.https.HttpsError(
        'internal',
        typeof err?.message === 'string' ? err.message : 'Unexpected error',
      );
    }
  });

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔄 MIGRATION: Copy users → users collection
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
export const migrateusersToUsers = functions
  .region('europe-west1')
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Auth required');
    }

    const batchSize = Math.min(Number(data?.batchSize) || 100, 500);
    const startAfterId = typeof data?.startAfter === 'string' ? data.startAfter as string : undefined;
    const copySubcollections = data?.copySubcollections === true;

    let q = db.collection('users')
      .orderBy(admin.firestore.FieldPath.documentId())
      .limit(batchSize);

    if (startAfterId) {
      q = q.startAfter(startAfterId);
    }

    const snap = await q.get();
    if (snap.empty) {
      return { done: true, processed: 0, message: 'Migration complete!' };
    }

    const writeBatch = db.batch();
    let processed = 0;

    for (const doc of snap.docs) {
      const targetRef = db.collection('users').doc(doc.id);
      writeBatch.set(targetRef, doc.data(), { merge: true });
      processed++;

      if (copySubcollections) {
        const subcols = await doc.ref.listCollections();
        for (const subcol of subcols) {
          const subDocs = await subcol.get();
          for (const subDoc of subDocs.docs) {
            const subTargetRef = db.collection('users')
              .doc(doc.id)
              .collection(subcol.id)
              .doc(subDoc.id);
            writeBatch.set(subTargetRef, subDoc.data(), { merge: true });
          }
        }
      }
    }

    await writeBatch.commit();

    const lastId = snap.docs[snap.docs.length - 1].id;
    return {
      done: false,
      processed,
      lastId,
      message: `Migrated ${processed} users. Call again with startAfter: "${lastId}"`,
    };
  });
