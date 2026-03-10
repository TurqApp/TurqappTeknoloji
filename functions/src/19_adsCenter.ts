import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

type Placement = "feed" | "shorts" | "explore";

const enumValues = {
  campaignStatus: new Set(["draft", "pendingReview", "approved", "paused", "active", "ended", "rejected"]),
  moderationStatus: new Set(["pending", "approved", "rejected"]),
  placements: new Set(["feed", "shorts", "explore"]),
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
      .map((v: unknown) => normalizeString(v))
      .filter((v: string) => v.length > 0);
    if (allowed.includes(uid)) return;
  }
  throw new functions.https.HttpsError("permission-denied", "admin_required");
}

async function getFlags() {
  const primarySnap = await db.collection("adminConfig").doc("adsFlags").get();
  const legacySnap = primarySnap.exists
    ? null
    : await db.collection("system_flags").doc("global").get();
  const data = primarySnap.data() ?? legacySnap?.data() ?? {};
  return {
    adsInfrastructureEnabled: data.adsInfrastructureEnabled !== false,
    adsAdminPanelEnabled: data.adsAdminPanelEnabled !== false,
    adsDeliveryEnabled: data.adsDeliveryEnabled === true,
    adsPublicVisibilityEnabled: data.adsPublicVisibilityEnabled === true,
    adsPreviewModeEnabled: data.adsPreviewModeEnabled !== false,
  };
}

function normalizeString(value: unknown): string {
  return String(value ?? "").trim();
}

function normalizeInt(value: unknown): number | null {
  if (value === null || value === undefined || value === "") return null;
  const n = Number(value);
  if (!Number.isFinite(n)) return null;
  return Math.trunc(n);
}

function normalizePlacement(value: unknown): Placement {
  const raw = normalizeString(value).toLowerCase();
  if (raw === "shorts") return "shorts";
  if (raw === "explore") return "explore";
  return "feed";
}

function parseDateMs(value: unknown): number {
  if (typeof value === "number" && Number.isFinite(value)) return Math.trunc(value);
  if (typeof value === "string") {
    const n = Number(value);
    if (Number.isFinite(n)) return Math.trunc(n);
    const date = Date.parse(value);
    if (Number.isFinite(date)) return date;
  }
  if (value && typeof value === "object") {
    const maybe = value as { toMillis?: () => number; _seconds?: number; seconds?: number };
    if (typeof maybe.toMillis === "function") return maybe.toMillis();
    if (typeof maybe._seconds === "number") return maybe._seconds * 1000;
    if (typeof maybe.seconds === "number") return maybe.seconds * 1000;
  }
  return Date.now();
}

function matchesTargeting(targeting: any, ctx: {
  userId: string;
  country: string;
  city: string;
  age: number | null;
  placement: Placement;
  appVersion: string;
  devicePlatform: string;
}) {
  const includeIds = Array.isArray(targeting?.includeUserIds) ? targeting.includeUserIds.map((v: unknown) => normalizeString(v)) : [];
  const excludeIds = Array.isArray(targeting?.excludeUserIds) ? targeting.excludeUserIds.map((v: unknown) => normalizeString(v)) : [];

  if (excludeIds.includes(ctx.userId)) return false;
  if (includeIds.length > 0 && !includeIds.includes(ctx.userId)) return false;

  const countries = Array.isArray(targeting?.countries) ? targeting.countries.map((v: unknown) => normalizeString(v).toLowerCase()) : [];
  if (countries.length > 0 && !countries.includes(ctx.country.toLowerCase())) return false;

  const cities = Array.isArray(targeting?.cities) ? targeting.cities.map((v: unknown) => normalizeString(v).toLowerCase()) : [];
  if (cities.length > 0 && !cities.includes(ctx.city.toLowerCase())) return false;

  const minAge = normalizeInt(targeting?.minAge);
  const maxAge = normalizeInt(targeting?.maxAge);
  if ((minAge !== null || maxAge !== null) && ctx.age === null) return false;
  if (ctx.age !== null && minAge !== null && ctx.age < minAge) return false;
  if (ctx.age !== null && maxAge !== null && ctx.age > maxAge) return false;

  const platforms = Array.isArray(targeting?.devicePlatforms)
    ? targeting.devicePlatforms.map((v: unknown) => normalizeString(v).toLowerCase())
    : [];
  if (platforms.length > 0 && !platforms.includes(ctx.devicePlatform.toLowerCase())) return false;

  const versions = Array.isArray(targeting?.appVersions)
    ? targeting.appVersions.map((v: unknown) => normalizeString(v))
    : [];
  if (versions.length > 0 && !versions.includes(ctx.appVersion)) return false;

  return true;
}

function normalizedKeyParts(values: unknown[] | undefined): string[] {
  if (!Array.isArray(values)) return [];
  const set = new Set<string>();
  for (const item of values) {
    const normalized = normalizeString(item).toUpperCase();
    if (normalized.length > 0) set.add(normalized);
  }
  return Array.from(set);
}

function buildTargetingKeys(data: admin.firestore.DocumentData | null): string[] {
  if (!data) return [];
  const targeting = (data.targeting ?? {}) as admin.firestore.DocumentData;
  const placements = Array.isArray(data.placementTypes)
    ? data.placementTypes
        .map((v: unknown) => normalizeString(v).toLowerCase())
        .filter((v) => v.length > 0)
    : [];
  const placementList = placements.length === 0 ? ["feed"] : Array.from(new Set(placements));

  const countries = normalizedKeyParts(
    Array.isArray(targeting.countries) ? targeting.countries : undefined
  );
  const cities = normalizedKeyParts(
    Array.isArray(targeting.cities) ? targeting.cities : undefined
  );
  const countryList = countries.length == 0 ? ["ANY"] : countries;
  const cityList = cities.length == 0 ? ["ANY"] : cities;

  const minAge = normalizeInt(targeting.minAge);
  const maxAge = normalizeInt(targeting.maxAge);
  const ageRange = `${minAge ?? 0}-${maxAge ?? 120}`;

  const keys: string[] = [];
  for (const country of countryList) {
    for (const city of cityList) {
      for (const place of placementList) {
        keys.push(`${country}:${city}:${ageRange}:${place}`);
      }
    }
  }
  return keys;
}

async function updateTargetingIndexKey(key: string, campaignId: string, include: boolean) {
  if (!key || !key.trim()) return;
  const ref = db.collection("ads_targeting_index").doc(key);
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.exists ? snap.data() ?? {} : {};
    const current = Array.isArray(data.campaignIds)
      ? new Set<string>(data.campaignIds.map((v: unknown) => normalizeString(v)))
      : new Set<string>();

    let changed = false;
    if (include) {
      if (!current.has(campaignId)) {
        current.add(campaignId);
        changed = true;
      }
    } else {
      if (current.delete(campaignId)) {
        changed = true;
      }
    }

    if (!changed) return;
    if (current.size === 0) {
      tx.delete(ref);
      return;
    }

    tx.set(
      ref,
      {
        key,
        campaignIds: Array.from(current),
        updatedAt: Date.now(),
      },
      { merge: true }
    );
  });
}

async function getCampaignDailySpend(campaignId: string, nowMs: number): Promise<number> {
  const start = new Date(nowMs);
  start.setHours(0, 0, 0, 0);
  const end = new Date(start.getTime());
  end.setDate(end.getDate() + 1);

  const snap = await db
    .collection("ads_daily_stats")
    .where("campaignId", "==", campaignId)
    .where("date", ">=", start.getTime())
    .where("date", "<", end.getTime())
    .limit(1)
    .get();

  if (snap.empty) return 0;
  const d = snap.docs[0].data();
  return Number(d.spend ?? 0) || 0;
}

export const adsSimulateDelivery = functions.region("europe-west3").https.onCall(async (data, context) => {
  await ensureAdmin(context);
  const flags = await getFlags();

  if (!flags.adsInfrastructureEnabled || !flags.adsAdminPanelEnabled) {
    return {
      hasAd: false,
      message: "ads_infrastructure_or_admin_panel_disabled",
      decisions: [],
    };
  }

  if (!flags.adsPreviewModeEnabled) {
    return {
      hasAd: false,
      message: "ads_preview_mode_disabled",
      decisions: [],
    };
  }

  const nowMs = Date.now();
  const userId = normalizeString(data?.userId || context.auth?.uid);
  const placement = normalizePlacement(data?.placement);
  const country = normalizeString(data?.country);
  const city = normalizeString(data?.city);
  const age = normalizeInt(data?.age);
  const appVersion = normalizeString(data?.appVersion);
  const devicePlatform = normalizeString(data?.devicePlatform || "ios");

  const campaignSnap = await db.collection("ads_campaigns").limit(200).get();
  const decisions: Array<{ campaignId: string; eligible: boolean; reasons: string[] }> = [];

  type Candidate = {
    id: string;
    data: admin.firestore.DocumentData;
  };

  const candidates: Candidate[] = [];

  for (const doc of campaignSnap.docs) {
    const c = doc.data();
    const reasons: string[] = [];
    const status = normalizeString(c.status);
    const campaignPlacements = Array.isArray(c.placementTypes)
      ? c.placementTypes.map((v: unknown) => normalizeString(v).toLowerCase())
      : [];

    if (!enumValues.campaignStatus.has(status)) {
      reasons.push("invalid_status");
    }
    if (!(status === "active" || status === "approved")) {
      reasons.push("campaign_inactive");
    }
    if (c.deliveryEnabled !== true) {
      reasons.push("delivery_disabled");
    }

    const startAt = parseDateMs(c.startAt);
    const endAt = parseDateMs(c.endAt);
    if (nowMs < startAt || nowMs > endAt) {
      reasons.push("schedule_mismatch");
    }

    if (!campaignPlacements.includes(placement)) {
      reasons.push("placement_mismatch");
    }

    const budgetType = normalizeString(c.budgetType);
    const totalBudget = Number(c.totalBudget ?? 0) || 0;
    const spentAmount = Number(c.spentAmount ?? 0) || 0;
    const dailyBudget = Number(c.dailyBudget ?? 0) || 0;

    if (budgetType === "lifetime" && totalBudget > 0 && spentAmount >= totalBudget) {
      reasons.push("budget_exhausted");
    } else if (budgetType === "daily" && dailyBudget > 0) {
      const dailySpend = await getCampaignDailySpend(doc.id, nowMs);
      if (dailySpend >= dailyBudget) {
        reasons.push("budget_exhausted");
      }
    }

    const targetOk = matchesTargeting(c.targeting ?? {}, {
      userId,
      country,
      city,
      age,
      placement,
      appVersion,
      devicePlatform,
    });
    if (!targetOk) {
      reasons.push("targeting_mismatch");
    }

    const creativeIds = Array.isArray(c.creativeIds) ? c.creativeIds.map((v: unknown) => normalizeString(v)).filter(Boolean) : [];
    if (creativeIds.length === 0) {
      reasons.push("creative_not_attached");
    }

    decisions.push({
      campaignId: doc.id,
      eligible: reasons.length === 0,
      reasons,
    });

    if (reasons.length === 0) {
      candidates.push({ id: doc.id, data: c });
    }
  }

  if (candidates.length === 0) {
    await db.collection("ads_delivery_logs").add({
      userId,
      placement,
      country,
      city,
      age,
      hasAd: false,
      selectedCampaignId: "",
      selectedCreativeId: "",
      decisions,
      message: "no_eligible_campaign",
      isPreview: true,
      createdAt: nowMs,
    });

    return {
      hasAd: false,
      message: "no_eligible_campaign",
      decisions,
    };
  }

  candidates.sort((a, b) => {
    const pa = Number(a.data.priority ?? 0) || 0;
    const pb = Number(b.data.priority ?? 0) || 0;
    if (pb !== pa) return pb - pa;
    const ba = Number(a.data.bidAmount ?? 0) || 0;
    const bb = Number(b.data.bidAmount ?? 0) || 0;
    return bb - ba;
  });

  const selected = candidates[0];
  const creativeIds = Array.isArray(selected.data.creativeIds)
    ? selected.data.creativeIds.map((v: unknown) => normalizeString(v)).filter(Boolean)
    : [];

  let selectedCreative: { id: string; data: admin.firestore.DocumentData } | null = null;
  if (creativeIds.length > 0) {
    const limitIds = creativeIds.slice(0, 10);
    const creativeSnap = await db
      .collection("ads_creatives")
      .where(admin.firestore.FieldPath.documentId(), "in", limitIds)
      .get();
    for (const c of creativeSnap.docs) {
      const moderation = normalizeString(c.data().moderationStatus);
      if (enumValues.moderationStatus.has(moderation) && moderation === "approved") {
        selectedCreative = { id: c.id, data: c.data() };
        break;
      }
    }
  }

  if (!selectedCreative) {
    await db.collection("ads_delivery_logs").add({
      userId,
      placement,
      country,
      city,
      age,
      hasAd: false,
      selectedCampaignId: selected.id,
      selectedCreativeId: "",
      decisions,
      message: "creative_not_approved",
      isPreview: true,
      createdAt: nowMs,
    });

    return {
      hasAd: false,
      message: "creative_not_approved",
      decisions,
    };
  }

  const campaignOut = {
    id: selected.id,
    ...selected.data,
  };
  const creativeOut = {
    id: selectedCreative.id,
    ...selectedCreative.data,
  };

  await db.collection("ads_delivery_logs").add({
    userId,
    placement,
    country,
    city,
    age,
    hasAd: true,
    selectedCampaignId: selected.id,
    selectedCreativeId: selectedCreative.id,
    decisions,
    message: "eligible",
    isPreview: true,
    createdAt: nowMs,
  });

  return {
    hasAd: true,
    message: "eligible",
    campaign: campaignOut,
    creative: creativeOut,
    decisions,
  };
});

export const adsLogEvent = functions.region("europe-west3").https.onCall(async (data, context) => {
  await ensureAdmin(context);

  const flags = await getFlags();
  if (!flags.adsInfrastructureEnabled) {
    throw new functions.https.HttpsError("failed-precondition", "ads_infrastructure_disabled");
  }

  const event = normalizeString(data?.event);
  const campaignId = normalizeString(data?.campaignId);
  const creativeId = normalizeString(data?.creativeId);
  const placement = normalizePlacement(data?.placement);
  const isPreview = data?.isPreview === true;
  const userId = normalizeString(data?.userId || context.auth?.uid);
  const destinationUrl = normalizeString(data?.destinationUrl);
  const extras = typeof data?.extras === "object" && data.extras ? data.extras : {};

  const nowMs = Date.now();
  const base = {
    campaignId,
    creativeId,
    userId,
    placement,
    isPreview,
    destinationUrl,
    event,
    extras,
    createdAt: nowMs,
  };

  await db.collection("ads_delivery_logs").add(base);

  if (event === "impression") {
    await db.collection("ads_impressions").add(base);
  }
  if (event === "click" || event === "ctaTap") {
    await db.collection("ads_clicks").add({
      ...base,
      ctaTap: event === "ctaTap",
    });
  }

  return { ok: true };
});

export const syncAdsTargetingIndex = functions
  .region("europe-west3")
  .firestore.document("ads_campaigns/{campaignId}")
  .onWrite(async (change, context) => {
    const campaignId = context.params.campaignId;
    const oldKeys = buildTargetingKeys(change.before.exists ? change.before.data() ?? null : null);
    const newKeys = buildTargetingKeys(change.after.exists ? change.after.data() ?? null : null);

    const toAdd = newKeys.filter((key) => !oldKeys.includes(key));
    const toRemove = oldKeys.filter((key) => !newKeys.includes(key));

    await Promise.all([
      ...toAdd.map((key) => updateTargetingIndexKey(key, campaignId, true)),
      ...toRemove.map((key) => updateTargetingIndexKey(key, campaignId, false)),
    ]);
    return null;
  });

export const adsAggregateDailyStats = functions
  .region("europe-west3")
  .pubsub.schedule("every 60 minutes")
  .onRun(async () => {
    const now = new Date();
    const dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const dayEnd = new Date(dayStart.getTime());
    dayEnd.setDate(dayEnd.getDate() + 1);

    const [impSnap, clickSnap] = await Promise.all([
      db
        .collection("ads_impressions")
        .where("createdAt", ">=", dayStart.getTime())
        .where("createdAt", "<", dayEnd.getTime())
        .get(),
      db
        .collection("ads_clicks")
        .where("createdAt", ">=", dayStart.getTime())
        .where("createdAt", "<", dayEnd.getTime())
        .get(),
    ]);

    type Stat = {
      impressions: number;
      clicks: number;
      uniqueUsers: Set<string>;
      spend: number;
      videoStarts: number;
      videoCompletes: number;
    };

    const byCampaign = new Map<string, Stat>();

    const ensure = (campaignId: string) => {
      if (!byCampaign.has(campaignId)) {
        byCampaign.set(campaignId, {
          impressions: 0,
          clicks: 0,
          uniqueUsers: new Set<string>(),
          spend: 0,
          videoStarts: 0,
          videoCompletes: 0,
        });
      }
      return byCampaign.get(campaignId)!;
    };

    for (const d of impSnap.docs) {
      const data = d.data();
      const campaignId = normalizeString(data.campaignId);
      if (!campaignId) continue;
      const st = ensure(campaignId);
      st.impressions += 1;
      const uid = normalizeString(data.userId);
      if (uid) st.uniqueUsers.add(uid);
    }

    for (const d of clickSnap.docs) {
      const data = d.data();
      const campaignId = normalizeString(data.campaignId);
      if (!campaignId) continue;
      const st = ensure(campaignId);
      st.clicks += 1;
      const uid = normalizeString(data.userId);
      if (uid) st.uniqueUsers.add(uid);
    }

    const eventSnap = await db
      .collection("ads_delivery_logs")
      .where("createdAt", ">=", dayStart.getTime())
      .where("createdAt", "<", dayEnd.getTime())
      .get();

    for (const d of eventSnap.docs) {
      const data = d.data();
      const campaignId = normalizeString(data.campaignId || data.selectedCampaignId);
      if (!campaignId) continue;
      const event = normalizeString(data.event);
      const st = ensure(campaignId);
      if (event === "videoStart") st.videoStarts += 1;
      if (event === "video100" || event === "complete") st.videoCompletes += 1;
    }

    const campaignSpendSnap = await db.collection("ads_campaigns").get();
    const spentByCampaign = new Map<string, number>();
    for (const c of campaignSpendSnap.docs) {
      const spent = Number(c.data().spentAmount ?? 0) || 0;
      spentByCampaign.set(c.id, spent);
    }

    const batch = db.batch();
    for (const [campaignId, st] of byCampaign.entries()) {
      const ctr = st.impressions > 0 ? (st.clicks / st.impressions) * 100 : 0;
      const spend = spentByCampaign.get(campaignId) ?? st.spend;
      const avgCpc = st.clicks > 0 ? spend / st.clicks : 0;
      const avgCpm = st.impressions > 0 ? (spend / st.impressions) * 1000 : 0;
      const videoCompletionRate = st.videoStarts > 0 ? (st.videoCompletes / st.videoStarts) * 100 : 0;
      const dateKey = `${campaignId}_${dayStart.getTime()}`;

      const ref = db.collection("ads_daily_stats").doc(dateKey);
      batch.set(
        ref,
        {
          campaignId,
          date: dayStart.getTime(),
          totalImpressions: st.impressions,
          uniqueReach: st.uniqueUsers.size,
          clicks: st.clicks,
          ctr,
          spend,
          avgCpc,
          avgCpm,
          videoCompletionRate,
          updatedAt: Date.now(),
        },
        { merge: true }
      );
    }

    await batch.commit();
    return null;
  });
