import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore } from "firebase-admin/firestore";
import { CallableRequest, HttpsError, onCall } from "firebase-functions/v2/https";
import * as functions from "firebase-functions";
import axios from "axios";

const REGION = getEnv("SHORT_LINK_REGION") || "us-central1";
const SHORT_LINK_INDEX_COLLECTION = "short_links_index";
const SHORT_LINK_DOMAIN = getEnv("SHORT_LINK_DOMAIN") || "turqapp.com";
const SHORT_LINK_ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";

type ShortLinkType = "post" | "story" | "user";

interface UpsertShortLinkPayload {
  type: ShortLinkType;
  entityId: string; // postId | storyId | userId
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

interface ShortLinkIndexDoc {
  type: ShortLinkType;
  key: string;
  entityId: string;
  shortId: string;
  slug: string;
  title: string;
  desc: string;
  imageUrl: string;
  expiresAt: number;
  createdAt: number;
  updatedAt: number;
  createdBy: string;
  status: "active" | "inactive";
}

function ensureAdmin() {
  if (getApps().length === 0) initializeApp();
}

function getEnv(name: string): string {
  return String(process.env[name] || "").trim();
}

function normalizeText(v: unknown, maxLength: number): string {
  return String(v || "").trim().slice(0, maxLength);
}

function normalizeType(v: unknown): ShortLinkType {
  const raw = String(v || "").trim().toLowerCase();
  if (raw === "post" || raw === "story" || raw === "user") return raw;
  throw new HttpsError("invalid-argument", "type post/story/user olmalı.");
}

function validateShortId(shortId: string) {
  if (!/^[A-Za-z0-9_-]{4,20}$/.test(shortId)) {
    throw new HttpsError("invalid-argument", "shortId formatı geçersiz.");
  }
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

function typePath(type: ShortLinkType): "p" | "s" | "u" {
  if (type === "post") return "p";
  if (type === "story") return "s";
  return "u";
}

function kvPrefix(type: ShortLinkType): "p" | "s" | "u" {
  return typePath(type);
}

function buildPublicUrl(type: ShortLinkType, id: string): string {
  return `https://${SHORT_LINK_DOMAIN}/${typePath(type)}/${id}`;
}

function normalizeExpiresAt(type: ShortLinkType, v: unknown): number {
  if (type !== "story") return 0;
  const n = Number(v || 0);
  return Number.isFinite(n) && n > 0 ? Math.floor(n) : 0;
}

async function syncToCloudflareKV(type: ShortLinkType, id: string, value: Record<string, unknown>) {
  const token = getEnv("CF_API_TOKEN");
  const accountId = getEnv("CF_ACCOUNT_ID");
  const namespaceId = getEnv("CF_KV_NAMESPACE_ID");
  if (!token || !accountId || !namespaceId) return;

  const key = `${kvPrefix(type)}:${id}`;
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
    const exists = await db.collection(SHORT_LINK_INDEX_COLLECTION).doc(`post:${candidate}`).get();
    if (!exists.exists) return candidate;
  }
  throw new HttpsError("resource-exhausted", "Kısa link üretilemedi, tekrar deneyin.");
}

export const upsertShortLink = onCall(
  { region: REGION },
  async (req: CallableRequest<UpsertShortLinkPayload>) => {
    ensureAdmin();
    const db = getFirestore();

    if (!req.auth?.uid) {
      throw new HttpsError("unauthenticated", "Giriş gerekli.");
    }

    const type = normalizeType(req.data?.type);
    const entityId = normalizeText(req.data?.entityId, 128);
    if (!entityId) throw new HttpsError("invalid-argument", "entityId zorunlu.");

    const title = normalizeText(req.data?.title, 140);
    const desc = normalizeText(req.data?.desc, 280);
    const imageUrl = normalizeText(req.data?.imageUrl, 1024);
    const expiresAt = normalizeExpiresAt(type, req.data?.expiresAt);
    const now = Date.now();

    let shortId = "";
    let slug = "";
    let indexId = "";

    if (type === "user") {
      slug = normalizeSlug(req.data?.slug);
      validateSlug(slug);
      shortId = slug;
      indexId = `user:${slug}`;
    } else {
      shortId = normalizeText(req.data?.shortId, 24);
      if (shortId) {
        validateShortId(shortId);
      } else {
        shortId = await findFreeShortId(db);
      }
      indexId = `${type}:${shortId}`;
    }

    const indexRef = db.collection(SHORT_LINK_INDEX_COLLECTION).doc(indexId);

    await db.runTransaction(async (tx) => {
      const existing = await tx.get(indexRef);
      if (existing.exists) {
        const current = existing.data() as ShortLinkIndexDoc;
        if (current.entityId !== entityId) {
          throw new HttpsError("already-exists", "Bu kısa link başka kayıt için kullanılıyor.");
        }
      }

      const doc: ShortLinkIndexDoc = {
        type,
        key: shortId,
        entityId,
        shortId,
        slug,
        title,
        desc,
        imageUrl,
        expiresAt,
        createdAt: existing.exists ? ((existing.data() as ShortLinkIndexDoc).createdAt || now) : now,
        updatedAt: now,
        createdBy: req.auth!.uid,
        status: "active",
      };
      tx.set(indexRef, doc, { merge: true });
    });

    const idForUrl = type === "user" ? slug : shortId;
    const publicUrl = buildPublicUrl(type, idForUrl);

    if (type === "post") {
      await db.collection("Posts").doc(entityId).set(
        {
          shortId,
          shortUrl: publicUrl,
          shortLinkUpdatedAt: now,
          shortLinkStatus: "active",
        },
        { merge: true }
      );
    } else if (type === "story") {
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
    } else {
      await db.collection("users").doc(entityId).set(
        {
          profileSlug: slug,
          profileUrl: publicUrl,
          shortLinkUpdatedAt: now,
        },
        { merge: true }
      );
    }

    try {
      await syncToCloudflareKV(type, idForUrl, {
        type,
        id: idForUrl,
        entityId,
        shortId,
        slug,
        title,
        desc,
        imageUrl,
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
      indexCollection: SHORT_LINK_INDEX_COLLECTION,
      domain: SHORT_LINK_DOMAIN,
    };
  }
);

export const resolveShortLink = onCall(
  { region: REGION },
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

    let resolvedId = "";
    let data: ShortLinkIndexDoc | null = null;
    for (const candidate of candidateIds) {
      const snap = await db
        .collection(SHORT_LINK_INDEX_COLLECTION)
        .doc(`${type}:${candidate}`)
        .get();
      if (snap.exists) {
        resolvedId = candidate;
        data = snap.data() as ShortLinkIndexDoc;
        break;
      }
    }

    if (!data || !resolvedId) {
      throw new HttpsError("not-found", "Kısa link bulunamadı.");
    }

    if (data.status !== "active") {
      throw new HttpsError("failed-precondition", "Kısa link pasif.");
    }
    if (data.type === "story" && data.expiresAt > 0 && Date.now() > data.expiresAt) {
      throw new HttpsError("deadline-exceeded", "Story link süresi dolmuş.");
    }

    return {
      ok: true,
      type: data.type,
      id: resolvedId,
      url: buildPublicUrl(data.type, resolvedId),
      indexCollection: SHORT_LINK_INDEX_COLLECTION,
      data,
    };
  }
);

export const shortLinkIndexConfig = onCall({ region: REGION }, async () => {
  return {
    ok: true,
    indexCollection: SHORT_LINK_INDEX_COLLECTION,
    domain: SHORT_LINK_DOMAIN,
    routes: ["/p/:id", "/s/:id", "/u/:id"],
    cloudflareKvSyncEnabled:
      !!getEnv("CF_API_TOKEN") &&
      !!getEnv("CF_ACCOUNT_ID") &&
      !!getEnv("CF_KV_NAMESPACE_ID"),
  };
});
