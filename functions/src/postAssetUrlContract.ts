const CDN_DOMAIN = "cdn.turqapp.com";
const STORAGE_HOST = "firebasestorage.googleapis.com";
const STORAGE_APP_BUCKET_HOST = "turqappteknoloji.firebasestorage.app";
const POSTS_PREFIX = "Posts/";
const USERS_PREFIX = "users/";

function normalizeText(value: unknown): string {
  return String(value || "").trim();
}

export function buildCanonicalPostAssetUrlFromStoragePath(storagePath: string): string {
  const normalized = normalizeText(storagePath).replace(/^\/+/, "");
  if (!normalized) return "";
  return `https://${CDN_DOMAIN}/${normalized}`;
}

export function buildCanonicalPostHlsUrl(docId: string): string {
  return buildCanonicalPostAssetUrlFromStoragePath(`Posts/${normalizeText(docId)}/hls/master.m3u8`);
}

export function buildCanonicalUserAssetUrlFromStoragePath(storagePath: string): string {
  const normalized = normalizeText(storagePath).replace(/^\/+/, "");
  if (!normalized) return "";
  return `https://${CDN_DOMAIN}/${normalized}`;
}

export function decodeStorageObjectPathFromUrl(rawUrl: string): string {
  const text = normalizeText(rawUrl);
  if (!text) return "";

  if (text.startsWith("gs://")) {
    const parts = text.replace("gs://", "").split("/");
    parts.shift();
    return parts.join("/");
  }

  try {
    const parsed = new URL(text);
    const objectIndex = parsed.pathname.indexOf("/o/");
    if (objectIndex >= 0) {
      return decodeURIComponent(parsed.pathname.slice(objectIndex + 3));
    }

    if (parsed.hostname === CDN_DOMAIN || parsed.hostname === "storage.googleapis.com") {
      const pathname = parsed.pathname.replace(/^\/+/, "");
      if (pathname.startsWith(STORAGE_APP_BUCKET_HOST + "/")) {
        return pathname.slice(STORAGE_APP_BUCKET_HOST.length + 1);
      }
      if (pathname.startsWith(POSTS_PREFIX)) {
        return pathname;
      }
    }
  } catch {
    return "";
  }

  return "";
}

function isKnownPublicPostAsset(relativeName: string): boolean {
  return (
    relativeName.startsWith("hls/") ||
    relativeName === "video.mp4" ||
    /^thumbnail\.(webp|jpg|jpeg|png)$/i.test(relativeName) ||
    /^image_\d+\.(webp|jpg|jpeg|png)$/i.test(relativeName)
  );
}

function isKnownPublicUserAsset(relativeName: string): boolean {
  return relativeName.length > 0;
}

export function canonicalizeKnownPublicPostAssetUrl(rawUrl: string, docId?: string): string {
  const text = normalizeText(rawUrl);
  if (!text) return "";

  const normalizedDocId = normalizeText(docId);
  const objectPath = decodeStorageObjectPathFromUrl(text);
  if (!objectPath || !objectPath.startsWith(POSTS_PREFIX)) {
    return text;
  }

  const relativeFromPosts = objectPath.slice(POSTS_PREFIX.length);
  const slashIndex = relativeFromPosts.indexOf("/");
  if (slashIndex <= 0) return text;

  const objectDocId = relativeFromPosts.slice(0, slashIndex);
  const relativeName = relativeFromPosts.slice(slashIndex + 1);
  if (normalizedDocId && objectDocId !== normalizedDocId) {
    return text;
  }
  if (!isKnownPublicPostAsset(relativeName)) {
    return text;
  }

  return buildCanonicalPostAssetUrlFromStoragePath(objectPath);
}

export function canonicalizeKnownPublicUserAssetUrl(rawUrl: string, uid?: string): string {
  const text = normalizeText(rawUrl);
  if (!text) return "";

  const normalizedUid = normalizeText(uid);
  const objectPath = decodeStorageObjectPathFromUrl(text);
  if (!objectPath || !objectPath.startsWith(USERS_PREFIX)) {
    return text;
  }

  const relativeFromUsers = objectPath.slice(USERS_PREFIX.length);
  const slashIndex = relativeFromUsers.indexOf("/");
  if (slashIndex <= 0) return text;

  const objectUid = relativeFromUsers.slice(0, slashIndex);
  const relativeName = relativeFromUsers.slice(slashIndex + 1);
  if (normalizedUid && objectUid !== normalizedUid) {
    return text;
  }
  if (!isKnownPublicUserAsset(relativeName)) {
    return text;
  }

  return buildCanonicalUserAssetUrlFromStoragePath(objectPath);
}
