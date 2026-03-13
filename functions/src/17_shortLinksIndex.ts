import { getApps, initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore } from "firebase-admin/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import * as functions from "firebase-functions";
import axios from "axios";

const REGION = getEnv("SHORT_LINK_REGION") || "us-central1";
const SHORT_LINK_ROUTE_COLLECTION = "shortRoutes";
const SHORT_LINK_DOMAIN = getEnv("SHORT_LINK_DOMAIN") || "turqapp.com";
const SHORT_LINK_CDN_DOMAIN = getEnv("SHORT_LINK_CDN_DOMAIN") || "cdn.turqapp.com";
const STORAGE_HOST = "firebasestorage.googleapis.com";
const STORAGE_APP_BUCKET_HOST = "turqappteknoloji.firebasestorage.app";
const SHORT_LINK_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

type ShortLinkType = "post" | "story" | "user" | "edu" | "job";
type RouteKind = "p" | "s" | "u" | "e" | "i";

interface UpsertShortLinkPayload {
  type: ShortLinkType;
  entityId: string; // postId | storyId | userId | jobId
  shortId?: string; // post/story için
  slug?: string; // user için (nickname)
  title?: string;
  desc?: string;
  imageUrl?: string;
  expiresAt?: number; // story için opsiyonel TTL
}

interface ResolveShortLinkPayload {
  type: ShortLinkType;
  id: string; // post/story: shortId, user: slug
}

interface ShortRouteDoc {
  routeKind: RouteKind;
  key: string;
  type: ShortLinkType;
  entityId: string;
  entityPath: string;
  shortId: string;
  shortUrl: string;
  status: "active" | "inactive";
  expiresAt: number;
  updatedAt: number;
}

async function findExistingRouteForEntity(
  db: FirebaseFirestore.Firestore,
  type: ShortLinkType,
  entityId: string
): Promise<{ shortId: string; routeKind: RouteKind } | null> {
  const snap = await db
    .collection(SHORT_LINK_ROUTE_COLLECTION)
    .where("entityId", "==", entityId)
    .limit(20)
    .get();

  if (snap.empty) return null;

  for (const doc of snap.docs) {
    const data = doc.data() as Partial<ShortRouteDoc>;
    const routeType = String(data.type || "").trim() as ShortLinkType;
    const status = String(data.status || "").trim();
    const shortId = String(data.shortId || "").trim();
    const routeKind = String(data.routeKind || "").trim() as RouteKind;
    if (
      routeType === type &&
      status === "active" &&
      shortId &&
      isPreferredShortId(shortId) &&
      ["p", "s", "u", "e", "i"].includes(routeKind)
    ) {
      return { shortId, routeKind };
    }
  }
  return null;
}

function ensureAdmin() {
  if (getApps().length === 0) initializeApp();
}

function ensureAuth(req: CallableRequest<unknown>): string {
  const uid = req.auth?.uid || "";
  if (!uid) {
    throw new HttpsError("unauthenticated", "Giriş gerekli.");
  }
  return uid;
}

function getEnv(name: string): string {
  const fromProcess = String(process.env[name] || "").trim();
  if (fromProcess) return fromProcess;
  try {
    const configValue = functions.config?.()?.shortlinks?.[name.toLowerCase()];
    return String(configValue || "").trim();
  } catch {
    return "";
  }
}

function normalizeText(v: unknown, maxLength: number): string {
  return String(v || "").trim().slice(0, maxLength);
}

function clampPreviewDescription(v: string): string {
  const text = String(v || "").replace(/\s+/g, " ").trim();
  if (!text) return "";
  // WhatsApp/Telegram preview alaninda yaklasik 4 satirlik gorunum icin.
  if (text.length <= 170) return text;
  return `${text.slice(0, 167).trimEnd()}...`;
}

function normalizeType(v: unknown): ShortLinkType {
  const raw = String(v || "").trim().toLowerCase();
  if (["post", "story", "user", "edu", "job"].includes(raw)) return raw as ShortLinkType;
  throw new HttpsError("invalid-argument", "type post/story/user/edu olmalı.");
}

function validateShortId(shortId: string) {
  if (!/^[A-Za-z0-9._-]{2,80}$/.test(shortId)) {
    throw new HttpsError("invalid-argument", "shortId formatı geçersiz.");
  }
}

function isPreferredShortId(shortId: string): boolean {
  const value = String(shortId || "").trim();
  if (!value) return false;
  return /^[A-Za-z0-9_-]{4,12}$/.test(value);
}

function normalizeSlug(v: unknown): string {
  const slug = String(v || "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "")
    .replace(/[^a-z0-9._-]/g, "")
    .slice(0, 40);
  return slug;
}

function pickOwnerUid(data: Record<string, unknown>): string {
  const candidates = [
    data.userID,
    data.userId,
    data.uid,
    data.ownerId,
    data.createdBy,
    data.authorId,
  ];
  for (const candidate of candidates) {
    const value = String(candidate || "").trim();
    if (value) return value;
  }
  return "";
}

function resolveCanonicalUserSlug(
  data: Record<string, unknown>,
  fallbackId: string
): string {
  const candidates = [
    data.profileSlug,
    data.usernameLower,
    data.username,
    data.nickname,
    data.userNickname,
    data.name,
    fallbackId,
  ];
  for (const candidate of candidates) {
    const slug = normalizeSlug(candidate);
    if (slug) return slug;
  }
  return normalizeSlug(fallbackId);
}

async function isAdminUid(
  db: FirebaseFirestore.Firestore,
  uid: string
): Promise<boolean> {
  if (!uid) return false;
  const claims = await getAuth().getUser(uid).then(
    (user) => (user.customClaims || {}) as Record<string, unknown>,
    () => ({}) as Record<string, unknown>
  );
  if (claims["admin"] === true) return true;

  const allowSnap = await db.doc("adminConfig/admin").get();
  const allowedRaw = allowSnap.data()?.allowedUserIds;
  if (!Array.isArray(allowedRaw)) return false;
  return allowedRaw
    .map((value: unknown) => String(value ?? "").trim())
    .filter((value: string) => value.length > 0)
    .includes(uid);
}

function validateSlug(slug: string) {
  if (!slug || !/^[a-z0-9._-]{2,40}$/.test(slug)) {
    throw new HttpsError("invalid-argument", "slug formatı geçersiz.");
  }
}

function randomShortId(length = 7): string {
  let out = "";
  for (let i = 0; i < length; i += 1) {
    const idx = Math.floor(Math.random() * SHORT_LINK_ALPHABET.length);
    out += SHORT_LINK_ALPHABET[idx];
  }
  return out;
}

function routeKindFor(type: ShortLinkType, entityId = ""): RouteKind {
  if (type === "post") return "p";
  if (type === "story") return "s";
  if (type === "user") return "u";
  if (type === "job") return "i";
  if (type === "edu" && (entityId.startsWith("tutoring:") || entityId.startsWith("job:"))) {
    return "i";
  }
  return "e";
}

function kvPrefix(type: ShortLinkType, entityId = ""): RouteKind {
  return routeKindFor(type, entityId);
}

function buildPublicUrl(routeKind: RouteKind, id: string): string {
  return `https://${SHORT_LINK_DOMAIN}/${routeKind}/${id}`;
}

function normalizeExpiresAt(type: ShortLinkType, v: unknown): number {
  if (type !== "story") return 0;
  const n = Number(v || 0);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : 0;
}

function pickFirstUrl(value: unknown): string {
  if (typeof value === "string") {
    const url = value.trim();
    if (url) return url;
  }
  if (Array.isArray(value)) {
    const first = value[0];
    if (typeof first === "string") {
      return first.trim();
    }
    if (first && typeof first === "object") {
      return String((first as Record<string, unknown>).url || "").trim();
    }
  }
  return "";
}

function pickBestImageFromData(data: Record<string, unknown>): string {
  const candidates: unknown[] = [
    data.imageUrl,
    data.thumbnail,
    data.thumbnailOfVideo,
    data.thumbnasilOfVideo,
    data.cover,
    data.poster,
    data.previewImage,
    data.logo,
    data.profileImage,
    data.photoUrl,
    data.pp,
    data.avatar,
    data.img,
    data.imgMap,
    data.img2,
    data.imgs,
    data.images,
    data.media,
  ];

  for (const c of candidates) {
    const picked = pickFirstUrl(c);
    if (picked) return picked;
  }
  return "";
}

function pickStoryPreviewImage(data: Record<string, unknown>): string {
  const direct = pickBestImageFromData(data);
  if (direct) return direct;
  const elements = data.elements;
  if (!Array.isArray(elements)) return "";
  for (const item of elements) {
    if (!item || typeof item !== "object") continue;
    const media = item as Record<string, unknown>;
    const fromMedia = pickBestImageFromData(media);
    if (fromMedia) return fromMedia;
  }
  return "";
}

async function buildPostMeta(
  db: FirebaseFirestore.Firestore,
  postId: string
): Promise<{ title: string; desc: string; imageUrl: string }> {
  const snap = await db.collection("Posts").doc(postId).get();
  if (!snap.exists) {
    return {
      title: "TurqApp Gonderisi",
      desc: "",
      imageUrl: "",
    };
  }

  const data = snap.data() || {};
  const authorNickname = normalizeText(
    data.authorNickname || data.nickname || data.userNickname,
    60
  );
  const caption = normalizeText(data.metin || data.caption, 280);
  const hasVideo =
    normalizeText(data.video, 16).length > 0 ||
    normalizeText(data.hlsMasterUrl, 16).length > 0;
  const thumbnail = normalizeText(data.thumbnail, 1024);
  const firstImage = normalizeText(pickFirstUrl(data.img), 1024);
  const imageUrl = hasVideo ? thumbnail : firstImage;

  const title = authorNickname
    ? `${authorNickname} yeni bir gonderi paylasti`
    : "TurqApp Gonderisi";

  return {
    title,
    desc: caption,
    imageUrl,
  };
}

async function buildEntityMetaImage(
  db: FirebaseFirestore.Firestore,
  type: ShortLinkType,
  entityId: string
): Promise<string> {
  const target = parseEntityTarget(db, type, entityId);
  if (!target) return "";
  const snap = await target.ref.get();
  if (!snap.exists) return "";
  const data = (snap.data() || {}) as Record<string, unknown>;
  return normalizeText(pickBestImageFromData(data), 1024);
}

async function buildUserMeta(
  db: FirebaseFirestore.Firestore,
  entityId: string
): Promise<{ title: string; desc: string; imageUrl: string }> {
  const snap = await db.collection("users").doc(entityId).get();
  if (!snap.exists) {
    return { title: "TurqApp Profili", desc: "", imageUrl: "" };
  }
  const data = (snap.data() || {}) as Record<string, unknown>;
  const nickname = normalizeText(
    data.nickname || data.userNickname || data.name,
    60
  );
  const bio = normalizeText(data.bio || data.about || data.desc, 170);
  const imageUrl = normalizeText(pickBestImageFromData(data), 1024);
  return {
    title: nickname ? `@${nickname} - TurqApp` : "TurqApp Profili",
    desc: bio,
    imageUrl,
  };
}

async function buildStoryMeta(
  db: FirebaseFirestore.Firestore,
  entityId: string
): Promise<{ title: string; desc: string; imageUrl: string }> {
  const snap = await db.collection("stories").doc(entityId).get();
  if (!snap.exists) {
    return { title: "TurqApp Hikayesi", desc: "", imageUrl: "" };
  }
  const data = (snap.data() || {}) as Record<string, unknown>;
  const nickname = normalizeText(
    data.authorNickname || data.nickname || data.userNickname,
    60
  );
  const imageUrl = normalizeText(pickStoryPreviewImage(data), 1024);
  return {
    title: nickname ? `${nickname} hikayesi` : "TurqApp Hikayesi",
    desc: "",
    imageUrl,
  };
}

async function buildEduMeta(
  db: FirebaseFirestore.Firestore,
  entityId: string
): Promise<{ title: string; desc: string; imageUrl: string }> {
  const target = parseEntityTarget(db, "edu", entityId);
  if (!target) {
    return { title: "TurqApp eğitim bağlantısı", desc: "", imageUrl: "" };
  }
  const snap = await target.ref.get();
  if (!snap.exists) {
    return { title: "TurqApp eğitim bağlantısı", desc: "", imageUrl: "" };
  }
  const data = (snap.data() || {}) as Record<string, unknown>;
  const title = normalizeText(
    data.baslik || data.title || data.ilanBasligi || data.meslek || data.name,
    140
  );
  const desc = normalizeText(
    data.aciklama || data.about || data.desc || data.metin || data.isTanimi,
    280
  );
  const imageUrl = normalizeText(pickBestImageFromData(data), 1024);
  return {
    title: title || "TurqApp eğitim bağlantısı",
    desc,
    imageUrl,
  };
}

async function buildJobMeta(
  db: FirebaseFirestore.Firestore,
  entityId: string
): Promise<{ title: string; desc: string; imageUrl: string }> {
  const cleanId = entityId.replace(/^job:/, "");
  const snap = await db.collection("isBul").doc(cleanId).get();
  if (!snap.exists) {
    return { title: "TurqApp İş İlanı", desc: "", imageUrl: "" };
  }
  const data = (snap.data() || {}) as Record<string, unknown>;
  const title = normalizeText(data.ilanBasligi || data.meslek || data.title, 140);
  const desc = normalizeText(data.about || data.isTanimi || data.desc, 280);
  const imageUrl = normalizeText(pickBestImageFromData(data), 1024);
  return {
    title: title || "TurqApp İş İlanı",
    desc,
    imageUrl,
  };
}

async function syncToCloudflareKV(type: ShortLinkType, entityId: string, id: string, value: Record<string, unknown>) {
  const token = getEnv("CF_API_TOKEN");
  const accountId = getEnv("CF_ACCOUNT_ID");
  const namespaceId = getEnv("CF_KV_NAMESPACE_ID");
  if (!token || !accountId || !namespaceId) {
    functions.logger.warn("shortLink cloudflare_kv_sync_disabled_missing_env", {
      hasToken: !!token,
      hasAccountId: !!accountId,
      hasNamespaceId: !!namespaceId,
      type,
      entityId,
      id,
    });
    return;
  }

  const key = `${kvPrefix(type, entityId)}:${id}`;
  const endpoint =
    `https://api.cloudflare.com/client/v4/accounts/${accountId}` +
    `/storage/kv/namespaces/${namespaceId}/values/${encodeURIComponent(key)}`;

  await axios.put(endpoint, JSON.stringify(value), {
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "text/plain; charset=utf-8",
    },
    timeout: 8000,
  });
}

async function findFreeShortId(db: FirebaseFirestore.Firestore): Promise<string> {
  for (let i = 0; i < 24; i += 1) {
    const candidate = randomShortId(7);
    const routeChecks = await Promise.all([
      db.collection(SHORT_LINK_ROUTE_COLLECTION).doc(`p:${candidate}`).get(),
      db.collection(SHORT_LINK_ROUTE_COLLECTION).doc(`s:${candidate}`).get(),
      db.collection(SHORT_LINK_ROUTE_COLLECTION).doc(`u:${candidate}`).get(),
      db.collection(SHORT_LINK_ROUTE_COLLECTION).doc(`e:${candidate}`).get(),
      db.collection(SHORT_LINK_ROUTE_COLLECTION).doc(`i:${candidate}`).get(),
    ]);
    if (routeChecks.every((snap) => !snap.exists)) return candidate;
  }
  throw new HttpsError("resource-exhausted", "Kısa link üretilemedi, tekrar deneyin.");
}

function parseEntityTarget(
  db: FirebaseFirestore.Firestore,
  type: ShortLinkType,
  entityId: string
): { ref: FirebaseFirestore.DocumentReference; path: string } | null {
  if (type === "post") {
    const ref = db.collection("Posts").doc(entityId);
    return { ref, path: ref.path };
  }
  if (type === "story") {
    const ref = db.collection("stories").doc(entityId);
    return { ref, path: ref.path };
  }
  if (type === "user") {
    const ref = db.collection("users").doc(entityId);
    return { ref, path: ref.path };
  }
  if (type === "job") {
    const cleanId = entityId.replace(/^job:/, "");
    const ref = db.collection("isBul").doc(cleanId);
    return { ref, path: ref.path };
  }
  if (entityId.startsWith("scholarship:")) {
    const ref = db
      .collection("catalog")
      .doc("education")
      .collection("scholarships")
      .doc(entityId.replace(/^scholarship:/, ""));
    return { ref, path: ref.path };
  }
  if (entityId.startsWith("practice-exam:")) {
    const ref = db.collection("practiceExams").doc(entityId.replace(/^practice-exam:/, ""));
    return { ref, path: ref.path };
  }
  if (entityId.startsWith("answer-key:")) {
    const ref = db.collection("books").doc(entityId.replace(/^answer-key:/, ""));
    return { ref, path: ref.path };
  }
  if (entityId.startsWith("question:")) {
    const ref = db.collection("questionBank").doc(entityId.replace(/^question:/, ""));
    return { ref, path: ref.path };
  }
  if (entityId.startsWith("tutoring:")) {
    const ref = db.collection("educators").doc(entityId.replace(/^tutoring:/, ""));
    return { ref, path: ref.path };
  }
  return null;
}

function buildEntityShortLinkDoc(
  routeKind: RouteKind,
  type: ShortLinkType,
  entityId: string,
  shortId: string,
  shortUrl: string,
  title: string,
  desc: string,
  imageUrl: string,
  expiresAt: number,
  updatedAt: number
) {
  return {
    routeKind,
    type,
    entityId,
    shortId,
    shortUrl,
    title,
    desc,
    imageUrl,
    status: "active" as const,
    expiresAt,
    updatedAt,
  };
}

function toDirectCdnImageUrl(imageUrl: string): string {
  let raw = String(imageUrl || "").trim();
  if (!raw) return "";

  const ogPrefix = `https://${SHORT_LINK_DOMAIN}/og-image?src=`;
  if (raw.startsWith(ogPrefix)) {
    try {
      const ogUrl = new URL(raw);
      const src = ogUrl.searchParams.get("src");
      if (src && src.trim()) raw = src.trim();
    } catch {
      // keep raw
    }
  }

  try {
    const parsed = new URL(raw);
    if (parsed.hostname === SHORT_LINK_CDN_DOMAIN) {
      return parsed.toString();
    }
    if (parsed.hostname === STORAGE_HOST || parsed.hostname === STORAGE_APP_BUCKET_HOST) {
      parsed.hostname = SHORT_LINK_CDN_DOMAIN;
      return parsed.toString();
    }
    return parsed.toString();
  } catch {
    return raw;
  }
}

function normalizeMetaPayload(
  type: ShortLinkType,
  entityId: string,
  title: string,
  desc: string,
  imageUrl: string
): { title: string; desc: string; imageUrl: string } {
  const nextTitle = normalizeText(title, 140);
  const nextDesc = clampPreviewDescription(normalizeText(desc, 280));
  const nextImage = toDirectCdnImageUrl(normalizeText(imageUrl, 2048));
  return { title: nextTitle, desc: nextDesc, imageUrl: nextImage };
}

export const upsertShortLink = onCall(
  { region: REGION, invoker: "public" },
  async (req: CallableRequest<UpsertShortLinkPayload>) => {
    ensureAdmin();
    const db = getFirestore();

    const type = normalizeType(req.data?.type);
    const callerUid = ensureAuth(req);
    const entityId = normalizeText(req.data?.entityId, 128);
    if (!entityId) throw new HttpsError("invalid-argument", "entityId zorunlu.");
    const entityTarget = parseEntityTarget(db, type, entityId);
    if (!entityTarget) {
      throw new HttpsError("not-found", "Entity bulunamadı.");
    }
    const entitySnap = await entityTarget.ref.get();
    if (!entitySnap.exists) {
      throw new HttpsError("not-found", "Entity bulunamadı.");
    }
    const entityData = (entitySnap.data() || {}) as Record<string, unknown>;
    const ownerUid = pickOwnerUid(entityData);
    const isAdmin = await isAdminUid(db, callerUid);
    const canPersistToEntity = isAdmin || ownerUid === callerUid;
    const canCustomizeRoute = canPersistToEntity;

    let title = normalizeText(req.data?.title, 140);
    let desc = normalizeText(req.data?.desc, 280);
    let imageUrl = normalizeText(req.data?.imageUrl, 1024);
    const expiresAt = normalizeExpiresAt(type, req.data?.expiresAt);
    const now = Date.now();

    if (type === "post") {
      const postMeta = await buildPostMeta(db, entityId);
      title = postMeta.title;
      if (!desc) desc = postMeta.desc;
      // Post paylasiminda gorsel secimini backend tek kaynaktan belirler:
      // foto: img[0], video: thumbnail
      imageUrl = postMeta.imageUrl || imageUrl;
    } else if (type === "user") {
      const userMeta = await buildUserMeta(db, entityId);
      if (!title) title = userMeta.title;
      if (!desc) desc = userMeta.desc;
      if (!imageUrl) imageUrl = userMeta.imageUrl;
    } else if (type === "story") {
      const storyMeta = await buildStoryMeta(db, entityId);
      if (!title) title = storyMeta.title;
      if (!desc) desc = storyMeta.desc;
      if (!imageUrl) imageUrl = storyMeta.imageUrl;
    } else if (type === "job") {
      const jobMeta = await buildJobMeta(db, entityId);
      if (!title) title = jobMeta.title;
      if (!desc) desc = jobMeta.desc;
      if (!imageUrl) imageUrl = jobMeta.imageUrl;
    } else if (type === "edu") {
      const eduMeta = await buildEduMeta(db, entityId);
      if (!title) title = eduMeta.title;
      if (!desc) desc = eduMeta.desc;
      if (!imageUrl) imageUrl = eduMeta.imageUrl;
    }
    if (!imageUrl) {
      imageUrl = await buildEntityMetaImage(db, type, entityId);
    }
    // Burs paylasimlarinda aciklama metnini kaldir:
    // preview'de sadece baslik + gorsel gosterilsin.
    if (type === "edu" && entityId.startsWith("scholarship:")) {
      desc = "";
    }
    const normalizedMeta = normalizeMetaPayload(type, entityId, title, desc, imageUrl);
    title = normalizedMeta.title;
    desc = normalizedMeta.desc;
    imageUrl = normalizedMeta.imageUrl;

    let shortId = "";
    let slug = "";
    const existingEntityShortLinkSnap = await entityTarget.ref
      .collection("shortLinks")
      .doc("public")
      .get();
    const existingEntityShortLink = existingEntityShortLinkSnap?.exists
      ? (existingEntityShortLinkSnap.data() as Record<string, unknown>)
      : null;

    if (type === "user") {
      const requestedSlug = normalizeSlug(req.data?.slug);
      const existingSlug = normalizeSlug(existingEntityShortLink?.shortId);
      const canonicalSlug = resolveCanonicalUserSlug(entityData, entityId);
      slug = canCustomizeRoute
        ? (requestedSlug || existingSlug || canonicalSlug)
        : (existingSlug || canonicalSlug);
      validateSlug(slug);
      shortId = slug;
    } else {
      shortId = normalizeText(req.data?.shortId, 24);
      if (!canCustomizeRoute) {
        shortId = "";
      }
      if (!shortId) {
        const existingShortId = String(existingEntityShortLink?.shortId || "").trim();
        if (isPreferredShortId(existingShortId)) {
          shortId = existingShortId;
        }
      }
      if (!shortId) {
        const existingRoute = await findExistingRouteForEntity(db, type, entityId);
        if (existingRoute?.shortId) {
          shortId = existingRoute.shortId;
        }
      }
      if (shortId) {
        validateShortId(shortId);
      } else {
        // Ilk olusturmada kisa id random uretilir; sonra entity shortLinks/public
        // ve shortRoutes uzerinden her zaman ayni id tekrar kullanilir.
        shortId = await findFreeShortId(db);
      }
    }

    const idForUrl = type === "user" ? slug : shortId;
    const routeKind = routeKindFor(type, entityId);
    const publicUrl = buildPublicUrl(routeKind, idForUrl);
    const resolvedImageUrl = imageUrl;
    const entityShortLinkDoc = buildEntityShortLinkDoc(
      routeKind,
      type,
      entityId,
      shortId,
      publicUrl,
      title,
      desc,
      resolvedImageUrl,
      expiresAt,
      now
    );
    const routeRef = db.collection(SHORT_LINK_ROUTE_COLLECTION).doc(`${routeKind}:${idForUrl}`);
    const routeSnap = await routeRef.get();
    if (routeSnap.exists) {
      const routeData = routeSnap.data() as ShortRouteDoc;
      if (routeData.entityId !== entityId) {
        throw new HttpsError("already-exists", "Bu kısa link başka kayıt için kullanılıyor.");
      }
    }

    if (type === "post" && canPersistToEntity) {
      await db.collection("Posts").doc(entityId).set(
        {
          shortId,
          shortUrl: publicUrl,
          shortLinkUpdatedAt: now,
          shortLinkStatus: "active",
        },
        { merge: true }
      );
    } else if (type === "job" && canPersistToEntity) {
      await db.collection("isBul").doc(entityId.replace(/^job:/, "")).set(
        {
          shortId,
          shortUrl: publicUrl,
          shortLinkUpdatedAt: now,
          shortLinkStatus: "active",
        },
        { merge: true }
      );
    } else if (type === "story" && canPersistToEntity) {
      await db.collection("stories").doc(entityId).set(
        {
          shortId,
          shortUrl: publicUrl,
          shortLinkUpdatedAt: now,
          shortLinkStatus: "active",
          shortLinkExpiresAt: expiresAt,
        },
        { merge: true }
      );
    } else if (type === "user" && canPersistToEntity) {
      await db.collection("users").doc(entityId).set(
        {
          profileSlug: slug,
          profileUrl: publicUrl,
          shortLinkUpdatedAt: now,
        },
        { merge: true }
      );
    }

    await entityTarget.ref.collection("shortLinks").doc("public").set(
      entityShortLinkDoc,
      { merge: true }
    );
    await routeRef.set(
      {
        routeKind,
        key: idForUrl,
        type,
        entityId,
        entityPath: `${entityTarget.path}/shortLinks/public`,
        shortId,
        shortUrl: publicUrl,
        status: "active",
        expiresAt,
        updatedAt: now,
      } satisfies ShortRouteDoc,
      { merge: true }
    );

    try {
      await syncToCloudflareKV(type, entityId, idForUrl, {
        type,
        id: idForUrl,
        entityId,
        routeKind,
        shortId,
        slug,
        title,
        desc,
        imageUrl: resolvedImageUrl,
        expiresAt,
      url: publicUrl,
      updatedAt: now,
      status: "active",
    });
    } catch (e) {
      functions.logger.error("upsertShortLink cloudflare_kv_sync_error", { type, id: idForUrl, entityId, error: e });
    }

    return {
      ok: true,
      type,
      id: idForUrl,
      shortId,
      slug,
      entityId,
      url: publicUrl,
      routeCollection: SHORT_LINK_ROUTE_COLLECTION,
      domain: SHORT_LINK_DOMAIN,
    };
  }
);

export const resolveShortLink = onCall(
  { region: REGION, invoker: "public" },
  async (req: CallableRequest<ResolveShortLinkPayload>) => {
    ensureAdmin();
    const db = getFirestore();

    const type = normalizeType(req.data?.type);
    const inputId = normalizeText(req.data?.id, 64);
    if (!inputId) throw new HttpsError("invalid-argument", "id zorunlu.");

    // user slug her zaman lowercase; post/story shortId case-sensitive.
    const candidateIds =
      type === "user"
        ? [inputId.toLowerCase()]
        : [inputId, inputId.toLowerCase(), inputId.toUpperCase()];

    const routeKinds: RouteKind[] =
      type === "post" ? ["p"] :
      type === "story" ? ["s"] :
      type === "user" ? ["u"] :
      type === "job" ? ["i"] :
      ["e", "i"];

    let resolvedId = "";
    let data: Record<string, unknown> | null = null;

    for (const candidate of candidateIds) {
      for (const routeKind of routeKinds) {
        const routeSnap = await db
          .collection(SHORT_LINK_ROUTE_COLLECTION)
          .doc(`${routeKind}:${candidate}`)
          .get();
        if (!routeSnap.exists) continue;
        const routeData = routeSnap.data() as ShortRouteDoc;
        if (routeData.status !== "active") {
          throw new HttpsError("failed-precondition", "Kısa link pasif.");
        }
        if (routeData.expiresAt > 0 && Date.now() > routeData.expiresAt) {
          throw new HttpsError("deadline-exceeded", "Story link süresi dolmuş.");
        }

        const entitySnap = await db.doc(routeData.entityPath).get();
        let entityData: Record<string, unknown> = entitySnap.exists
          ? (entitySnap.data() as Record<string, unknown>)
          : {};

        // Backward compatibility:
        // Some routes may exist while entityPath shortLinks/public doc is missing.
        // In that case rebuild meta from main entity doc.
        if (!entitySnap.exists) {
          if (routeData.type === "post") {
            const postSnap = await db.collection("Posts").doc(routeData.entityId).get();
            if (!postSnap.exists) continue;
            const postMeta = await buildPostMeta(db, routeData.entityId);
            entityData = {
              title: postMeta.title,
              desc: postMeta.desc,
              imageUrl: postMeta.imageUrl,
              status: "active",
              updatedAt: routeData.updatedAt || Date.now(),
              expiresAt: 0,
            };
          } else if (routeData.type === "user") {
            const userMeta = await buildUserMeta(db, routeData.entityId);
            entityData = { title: userMeta.title, desc: userMeta.desc, imageUrl: userMeta.imageUrl, status: "active", updatedAt: routeData.updatedAt || Date.now(), expiresAt: 0 };
          } else if (routeData.type === "story") {
            const storyMeta = await buildStoryMeta(db, routeData.entityId);
            entityData = { title: storyMeta.title, desc: storyMeta.desc, imageUrl: storyMeta.imageUrl, status: "active", updatedAt: routeData.updatedAt || Date.now(), expiresAt: 0 };
          } else if (routeData.type === "job") {
            const jobMeta = await buildJobMeta(db, routeData.entityId);
            entityData = { title: jobMeta.title, desc: jobMeta.desc, imageUrl: jobMeta.imageUrl, status: "active", updatedAt: routeData.updatedAt || Date.now(), expiresAt: 0 };
          } else if (routeData.type === "edu") {
            const eduMeta = await buildEduMeta(db, routeData.entityId);
            entityData = { title: eduMeta.title, desc: eduMeta.desc, imageUrl: eduMeta.imageUrl, status: "active", updatedAt: routeData.updatedAt || Date.now(), expiresAt: 0 };
          } else {
            continue;
          }
        }

        const hasTitle = String(entityData.title || "").trim().length > 0;
        const hasDesc = String(entityData.desc || "").trim().length > 0;
        const hasImage = String(entityData.imageUrl || "").trim().length > 0;
        if (!hasTitle || !hasDesc || !hasImage) {
          if (routeData.type === "post") {
            const postMeta = await buildPostMeta(db, routeData.entityId);
            entityData = {
              ...entityData,
              imageUrl: postMeta.imageUrl,
              title: String(entityData.title || postMeta.title || ""),
              desc: String(entityData.desc || postMeta.desc || ""),
            };
          } else if (routeData.type === "user") {
            const userMeta = await buildUserMeta(db, routeData.entityId);
            entityData = {
              ...entityData,
              title: String(entityData.title || userMeta.title || ""),
              desc: String(entityData.desc || userMeta.desc || ""),
              imageUrl: String(entityData.imageUrl || userMeta.imageUrl || ""),
            };
          } else if (routeData.type === "story") {
            const storyMeta = await buildStoryMeta(db, routeData.entityId);
            entityData = {
              ...entityData,
              title: String(entityData.title || storyMeta.title || ""),
              desc: String(entityData.desc || storyMeta.desc || ""),
              imageUrl: String(entityData.imageUrl || storyMeta.imageUrl || ""),
            };
          } else if (routeData.type === "job") {
            const jobMeta = await buildJobMeta(db, routeData.entityId);
            entityData = {
              ...entityData,
              title: String(entityData.title || jobMeta.title || ""),
              desc: String(entityData.desc || jobMeta.desc || ""),
              imageUrl: String(entityData.imageUrl || jobMeta.imageUrl || ""),
            };
          } else if (routeData.type === "edu") {
            const eduMeta = await buildEduMeta(db, routeData.entityId);
            entityData = {
              ...entityData,
              title: String(entityData.title || eduMeta.title || ""),
              desc: String(entityData.desc || eduMeta.desc || ""),
              imageUrl: String(entityData.imageUrl || eduMeta.imageUrl || ""),
            };
          } else {
            const fallbackImage = await buildEntityMetaImage(
              db,
              routeData.type,
              routeData.entityId
            );
            if (fallbackImage) {
              entityData = {
                ...entityData,
                imageUrl: fallbackImage,
              };
            }
          }
        }
        const normalized = normalizeMetaPayload(
          routeData.type,
          routeData.entityId,
          String(entityData.title || ""),
          String(entityData.desc || ""),
          String(entityData.imageUrl || "")
        );
        entityData = {
          ...entityData,
          title: normalized.title,
          desc: normalized.desc,
          imageUrl: normalized.imageUrl,
        };
        resolvedId = candidate;
        data = {
          type: routeData.type,
          entityId: routeData.entityId,
          shortId: routeData.shortId,
          title: String(entityData.title || ""),
          desc: String(entityData.desc || ""),
          imageUrl: String(entityData.imageUrl || ""),
          expiresAt: Number(entityData.expiresAt || routeData.expiresAt || 0),
          updatedAt: Number(entityData.updatedAt || routeData.updatedAt || Date.now()),
          status: String(entityData.status || routeData.status || "active") as "active" | "inactive",
        };
        break;
      }
      if (data) break;
    }
    if (!data || !resolvedId) {
      throw new HttpsError("not-found", "Kısa link bulunamadı.");
    }

    if (String(data.status || "") !== "active") {
      throw new HttpsError("failed-precondition", "Kısa link pasif.");
    }
    const resolvedType = String(data.type || "") as ShortLinkType;
    const resolvedExpiresAt = Number(data.expiresAt || 0);
    if (resolvedType === "story" && resolvedExpiresAt > 0 && Date.now() > resolvedExpiresAt) {
      throw new HttpsError("deadline-exceeded", "Story link süresi dolmuş.");
    }

    return {
      ok: true,
      type: resolvedType,
      id: resolvedId,
      url: buildPublicUrl(
        routeKindFor(resolvedType, String(data.entityId || "")),
        resolvedId
      ),
      routeCollection: SHORT_LINK_ROUTE_COLLECTION,
      data,
    };
  }
);

export const shortLinkIndexConfig = onCall({ region: REGION, invoker: "public" }, async () => {
  return {
    ok: true,
    routeCollection: SHORT_LINK_ROUTE_COLLECTION,
    domain: SHORT_LINK_DOMAIN,
    routes: ["/p/:id", "/s/:id", "/u/:id", "/e/:id", "/i/:id"],
    cloudflareKvSyncEnabled:
      !!getEnv("CF_API_TOKEN") &&
      !!getEnv("CF_ACCOUNT_ID") &&
      !!getEnv("CF_KV_NAMESPACE_ID"),
  };
});
