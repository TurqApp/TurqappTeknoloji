import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

const DEFAULT_REPORT_CATEGORIES: Record<string, { title: string; enabled: boolean; threshold: number }> = {
  impersonation: { title: "Taklit / Sahte Hesap / Kimlik Kullanımı", enabled: true, threshold: 5 },
  copyright: { title: "Telif / İzinsiz İçerik Kullanımı", enabled: true, threshold: 5 },
  harassment: { title: "Taciz / Hedef Gösterme / Zorbalık", enabled: true, threshold: 5 },
  hate_speech: { title: "Nefret Söylemi", enabled: true, threshold: 5 },
  nudity: { title: "Çıplaklık / Cinsel İçerik", enabled: true, threshold: 5 },
  violence: { title: "Şiddet / Tehdit", enabled: true, threshold: 5 },
  spam: { title: "Spam / Alakasız Tekrar İçerik", enabled: true, threshold: 5 },
  scam: { title: "Dolandırıcılık / Yanıltma", enabled: true, threshold: 5 },
  misinformation: { title: "Yanlış Bilgi / Manipülasyon", enabled: true, threshold: 5 },
  illegal_content: { title: "Yasa Dışı İçerik", enabled: true, threshold: 5 },
  child_safety: { title: "Çocuk Güvenliği İhlali", enabled: true, threshold: 5 },
  self_harm: { title: "Kendine Zarar Verme / İntihar Teşviki", enabled: true, threshold: 5 },
  privacy_violation: { title: "Gizlilik İhlali", enabled: true, threshold: 5 },
  fake_engagement: { title: "Sahte Etkileşim / Bot / Manipülatif Büyütme", enabled: true, threshold: 5 },
  other: { title: "Diğer", enabled: true, threshold: 5 },
};

const DEFAULT_REPORTS_CONFIG = {
  enabled: true,
  defaultThreshold: 5,
  notifyAboveThreshold: true,
  autoHidePostsAtThreshold: true,
  categories: DEFAULT_REPORT_CATEGORIES,
};

function ensureAuth(context: functions.https.CallableContext) {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "auth_required");
  }
}

async function ensureAdmin(context: functions.https.CallableContext) {
  ensureAuth(context);
  const uid = context.auth!.uid;
  const claims = context.auth?.token as { admin?: unknown } | undefined;
  if (claims?.admin === true) return;

  const allowSnap = await db.doc("adminConfig/admin").get();
  const allowedRaw = allowSnap.data()?.allowedUserIds;
  if (Array.isArray(allowedRaw)) {
    const allowed = allowedRaw
      .map((v: unknown) => String(v ?? "").trim())
      .filter((v: string) => v.length > 0);
    if (allowed.includes(uid)) return;
  }

  throw new functions.https.HttpsError("permission-denied", "admin_required");
}

async function ensureAdminByUid(uid: string) {
  const normalizedUid = uid.trim();
  if (!normalizedUid) {
    throw new functions.https.HttpsError("unauthenticated", "auth_required");
  }

  const allowSnap = await db.doc("adminConfig/admin").get();
  const allowedRaw = allowSnap.data()?.allowedUserIds;
  if (Array.isArray(allowedRaw)) {
    const allowed = allowedRaw
      .map((v: unknown) => String(v ?? "").trim())
      .filter((v: string) => v.length > 0);
    if (allowed.includes(normalizedUid)) return;
  }

  throw new functions.https.HttpsError("permission-denied", "admin_required");
}

function asMap(raw: unknown): Record<string, unknown> {
  if (raw && typeof raw === "object" && !Array.isArray(raw)) {
    return raw as Record<string, unknown>;
  }
  return {};
}

function asString(raw: unknown): string {
  return String(raw ?? "").trim();
}

function asBool(raw: unknown): boolean {
  return raw === true;
}

function toNonNegativeInt(raw: unknown): number {
  const n = Number(raw);
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.trunc(n));
}

function resolveThreshold(config: Record<string, unknown>, categoryKey: string): number {
  const categories = asMap(config["categories"]);
  const category = asMap(categories[categoryKey]);
  const categoryThreshold = toNonNegativeInt(category["threshold"]);
  if (categoryThreshold > 0) return categoryThreshold;
  const fallback = toNonNegativeInt(config["defaultThreshold"]);
  return fallback > 0 ? fallback : 5;
}

export const ensureReportsConfig = functions
  .region("europe-west3")
  .https
  .onCall(async (_data, context) => {
    await ensureAdmin(context);

    const ref = db.doc("adminConfig/reports");
    await ref.set(DEFAULT_REPORTS_CONFIG, { merge: true });
    const snap = await ref.get();
    return {
      ok: true,
      config: snap.data() ?? DEFAULT_REPORTS_CONFIG,
    };
  });

export const submitReport = functions
  .region("europe-west3")
  .https
  .onCall(async (data, context) => {
    ensureAuth(context);
    await db.doc("adminConfig/reports").set(DEFAULT_REPORTS_CONFIG, { merge: true });
    const authUid = asString(context.auth?.uid);
    const reporterUserId = asString(data?.reporterUserId) || authUid;
    if (!reporterUserId || reporterUserId != authUid) {
      throw new functions.https.HttpsError("permission-denied", "reporter_mismatch");
    }
    const targetType = asString(data?.targetType);
    const targetId = asString(data?.targetId);
    const targetOwnerId = asString(data?.targetOwnerId);
    const categoryKey = asString(data?.categoryKey) || "other";
    const title = asString(data?.title);
    const description = asString(data?.description);
    const postId = asString(data?.postId);
    const commentId = asString(data?.commentId);
    const source = asString(data?.source) || "app";

    if (!targetType || !targetId) {
      throw new functions.https.HttpsError("invalid-argument", "target_required");
    }
    if (!["user", "post", "comment"].includes(targetType)) {
      throw new functions.https.HttpsError("invalid-argument", "invalid_target_type");
    }

    const nowMs = Date.now();
    const targetKey = `${targetType}_${targetId}`;
    const aggregateRef = db.collection("reportAggregates").doc(targetKey);
    const reasonRef = aggregateRef.collection("reasons").doc(categoryKey);
    const reporterRef = reasonRef.collection("reporters").doc(reporterUserId);

    await aggregateRef.set({
      targetType,
      targetId,
      targetKey,
      targetOwnerId,
      status: "open",
      updatedAt: nowMs,
      createdAt: nowMs,
    }, { merge: true });

    await reasonRef.set({
      categoryKey,
      title,
      description,
      updatedAt: nowMs,
      createdAt: nowMs,
    }, { merge: true });

    await reporterRef.set({
      reporterUserId,
      categoryKey,
      title,
      description,
      targetType,
      targetId,
      targetKey,
      targetOwnerId,
      status: "open",
      createdAt: nowMs,
      updatedAt: nowMs,
      source,
      userID: targetOwnerId,
      postID: postId,
      yorumID: commentId,
      timeStamp: nowMs,
      sikayetTitle: title,
      sikayetDesc: description,
    }, { merge: true });

    return {
      ok: true,
      targetKey,
      categoryKey,
      reporterUserId,
    };
  });

export const onReporterCreate = functions.firestore
  .document("reportAggregates/{targetKey}/reasons/{categoryKey}/reporters/{reporterUserId}")
  .onCreate(async (snap, context) => {
    const raw = snap.data() ?? {};
    await db.doc("adminConfig/reports").set(DEFAULT_REPORTS_CONFIG, { merge: true });
    const configSnap = await db.doc("adminConfig/reports").get();
    const config = {
      ...DEFAULT_REPORTS_CONFIG,
      ...asMap(configSnap.data()),
    };

    if (config.enabled === false) {
      return null;
    }

    const targetKeyParam = context.params.targetKey as string;
    const categoryKeyParam = context.params.categoryKey as string;
    const reporterUserId = context.params.reporterUserId as string;
    const commentId = asString(raw["commentID"] ?? raw["yorumID"]);
    const postId = asString(raw["postID"]);
    const userId = asString(raw["userID"]);
    const targetType = asString(raw["targetType"]) ||
      (commentId ? "comment" : postId ? "post" : "user");
    const targetId = asString(raw["targetId"]) || (commentId || postId || userId);
    if (!targetId) {
      return null;
    }

    const categoryKey = asString(raw["categoryKey"]) || categoryKeyParam || "other";
    const targetOwnerId = asString(raw["targetOwnerId"]) || userId;
    const targetKey = asString(raw["targetKey"]) || targetKeyParam || `${targetType}_${targetId}`;
    const createdAt = toNonNegativeInt(raw["createdAt"] ?? raw["timeStamp"]) || Date.now();
    const threshold = resolveThreshold(config, categoryKey);
    const aggregateRef = db.collection("reportAggregates").doc(targetKey);
    const reasonRef = aggregateRef.collection("reasons").doc(categoryKey);
    const postRef = targetType === "post" ? db.collection("Posts").doc(targetId) : null;

    await snap.ref.set({
      reporterUserId,
      targetType,
      targetId,
      targetKey,
      targetOwnerId,
      categoryKey,
      createdAt,
      updatedAt: createdAt,
      status: asString(raw["status"]) || "open",
    }, { merge: true });

    await db.runTransaction(async (tx) => {
      const aggregateSnap = await tx.get(aggregateRef);
      const aggregate = aggregateSnap.data() ?? {};
      const reasonSnap = await tx.get(reasonRef);
      const reasonData = reasonSnap.data() ?? {};
      const previousCount = toNonNegativeInt(reasonData["count"]);
      const nextCount = previousCount + 1;
      const thresholdsReached = asMap(aggregate["thresholdsReached"]);
      const alreadyReached = asBool(thresholdsReached[categoryKey]);
      const nowMs = Date.now();

      const aggregatePatch: Record<string, unknown> = {
        targetType,
        targetId,
        targetKey,
        targetOwnerId,
        count: admin.firestore.FieldValue.increment(1),
        lastReportAt: createdAt,
        lastCategoryKey: categoryKey,
        latestReportId: reporterUserId,
        updatedAt: nowMs,
        status: alreadyReached ? (aggregate["status"] ?? "open") : "open",
      };

      if (!aggregateSnap.exists) {
        aggregatePatch["createdAt"] = nowMs;
      }

      tx.set(reasonRef, {
        categoryKey,
        title: asString(raw["title"] ?? raw["sikayetTitle"]) || categoryKey,
        description: asString(raw["description"] ?? raw["sikayetDesc"]),
        count: admin.firestore.FieldValue.increment(1),
        lastReportAt: createdAt,
        updatedAt: nowMs,
        createdAt: reasonSnap.exists
          ? toNonNegativeInt(reasonData["createdAt"]) || nowMs
          : nowMs,
      }, { merge: true });

      const reachedNow = nextCount >= threshold;
      if (!alreadyReached && reachedNow) {
        aggregatePatch[`thresholdsReached.${categoryKey}`] = true;
        aggregatePatch["requiresAdminReview"] = true;
        aggregatePatch["status"] = "threshold_reached";
        aggregatePatch["thresholdReachedAt"] = nowMs;
        aggregatePatch["autoHiddenAt"] = nowMs;
        aggregatePatch["thresholdCategoryKey"] = categoryKey;

        if (postRef && config.autoHidePostsAtThreshold !== false) {
          tx.set(postRef, {
            gizlendi: true,
            reportStatus: "auto_hidden",
            "moderation.status": "shadow_hidden",
            "moderation.reportAutoHiddenAt": nowMs,
            "moderation.reportThresholdCategory": categoryKey,
            "moderation.lastReportAt": createdAt,
            "moderation.reportReviewState": "pending",
            "moderation.reportCount": admin.firestore.FieldValue.increment(1),
          }, { merge: true });
        }
      } else if (postRef) {
        tx.set(postRef, {
          "moderation.lastReportAt": createdAt,
          "moderation.reportCount": admin.firestore.FieldValue.increment(1),
        }, { merge: true });
      }

      tx.set(aggregateRef, aggregatePatch, { merge: true });
    });

    return null;
  });

export const reviewReportedTarget = functions
  .region("europe-west3")
  .https
  .onCall(async (data, context) => {
    const fallbackUid = asString(data?.uid);
    if (context.auth?.uid) {
      await ensureAdmin(context);
    } else {
      await ensureAdminByUid(fallbackUid);
    }
    const aggregateId = asString(data?.aggregateId);
    const action = asString(data?.action);
    if (!aggregateId) {
      throw new functions.https.HttpsError("invalid-argument", "aggregate_required");
    }
    if (action !== "restore" && action !== "keep_hidden") {
      throw new functions.https.HttpsError("invalid-argument", "invalid_action");
    }

    const aggregateRef = db.collection("reportAggregates").doc(aggregateId);
    const uid = asString(context.auth?.uid) || fallbackUid;

    await db.runTransaction(async (tx) => {
      const aggregateSnap = await tx.get(aggregateRef);
      if (!aggregateSnap.exists) {
        throw new functions.https.HttpsError("not-found", "aggregate_not_found");
      }

      const aggregate = aggregateSnap.data() ?? {};
      const targetType = asString(aggregate["targetType"]);
      const targetId = asString(aggregate["targetId"]);
      const nowMs = Date.now();

      tx.set(aggregateRef, {
        status: action === "restore" ? "restored" : "actioned_hidden",
        requiresAdminReview: false,
        reviewedAt: nowMs,
        reviewedBy: uid,
        reviewAction: action,
      }, { merge: true });

      if (targetType === "post" && targetId) {
        const postRef = db.collection("Posts").doc(targetId);
        if (action === "restore") {
          tx.set(postRef, {
            gizlendi: false,
            reportStatus: "restored",
            "moderation.status": "active",
            "moderation.reportReviewState": "restored",
            "moderation.restoredAt": nowMs,
            "moderation.reviewedBy": uid,
          }, { merge: true });
        } else {
          tx.set(postRef, {
            gizlendi: true,
            reportStatus: "actioned_hidden",
            "moderation.status": "shadow_hidden",
            "moderation.reportReviewState": "confirmed_hidden",
            "moderation.reviewedAt": nowMs,
            "moderation.reviewedBy": uid,
          }, { merge: true });
        }
      }
    });

    return { ok: true };
  });
