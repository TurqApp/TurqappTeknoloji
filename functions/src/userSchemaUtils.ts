import * as admin from "firebase-admin";

export const LEGACY_DEFAULT_AVATAR_URL =
  "https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/profileImage.png?alt=media&token=4e8e9d1f-658b-4c34-b8da-79cfe09acef2";

export const normalizePhone = (raw: string | undefined | null): string => {
  if (!raw) return "";
  const digits = String(raw).replace(/[^0-9]/g, "");
  if (digits.length >= 10) {
    return digits.substring(digits.length - 10);
  }
  return digits;
};

export const normalizeUsernameLower = (raw: unknown): string => {
  const s = String(raw ?? "")
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "");
  return s.replace(/[^a-z0-9._]/g, "");
};

export const normalizeAvatarUrl = (raw: unknown): string => {
  const value = String(raw ?? "").trim();
  if (!value) return "";

  if (value === LEGACY_DEFAULT_AVATAR_URL) return "";

  const lower = value.toLowerCase();
  if (
    lower.includes("/o/profileimage.png") ||
    lower.endsWith("/profileimage.png") ||
    lower.endsWith("profileimage.png")
  ) {
    return "";
  }

  return value;
};

export const parseForceFollowUids = (
  data: FirebaseFirestore.DocumentData | undefined
): string[] => {
  if (!data) return [];
  const enabled = data.enabled;
  if (enabled === false) return [];

  const out = new Set<string>();
  const addOne = (v: unknown) => {
    if (typeof v !== "string") return;
    const trimmed = v.trim();
    if (trimmed) out.add(trimmed);
  };
  const addMany = (arr: unknown) => {
    if (!Array.isArray(arr)) return;
    for (const v of arr) addOne(v);
  };

  addOne(data.requiredUserIds);
  addMany(data.requiredUserIds);
  addOne(data.equiredUserIds);
  addMany(data.equiredUserIds);
  addOne(data.requiredUserId);
  addOne(data.uid);
  addOne(data.userId);

  return Array.from(out);
};

export const parseLegacyCreatedDateToTimestamp = (raw: unknown) => {
  if (typeof raw === "number" && Number.isFinite(raw) && raw > 0) {
    return admin.firestore.Timestamp.fromMillis(Math.floor(raw));
  }
  if (typeof raw === "string") {
    const n = Number(raw);
    if (Number.isFinite(n) && n > 0) {
      return admin.firestore.Timestamp.fromMillis(Math.floor(n));
    }
  }
  return null;
};

export const toNonNegativeInt = (raw: unknown): number => {
  const n = Number(raw);
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.trunc(n));
};
