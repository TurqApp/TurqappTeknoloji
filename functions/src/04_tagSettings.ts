// src/04_tagSettings.ts
// Tag üretimi: sadece caption -> tags + hashtags
// Tag index: /tags/{tag} + /tags/{tag}/posts/{postId}

import { initializeApp, getApps } from "firebase-admin/app";
import { getFirestore, FieldValue } from "firebase-admin/firestore";

function ensureAdmin() {
  if (getApps().length === 0) initializeApp();
}

export type TagSettings = {
  stopwords: string[];   // kelimeler
  suffixes: string[];    // ekler (tr)
  bannedWords: string[]; // tamamen yasak
  tagMinLength: number;
  tagMaxLength: number;
  maxTags: number;       // system tags max
  trendThreshold: number;
  trendWindowHours: number;
  enableBigrams: boolean;
  bigram: {
    minScore: number;
    joinChar: string;
    allowList: [string, string][];
    denyList: [string, string][];
  };
};

export type GenerateTagsInput = {
  caption: string;
};

export type GenerateTagsOutput = {
  userHashtags: string[]; // #.. ile gelenler (caption’dan)
  finalTags: string[];    // system tags
};

export type GenerateTagDetails = {
  hashtags: string[];
  mentions: string[];
  captionTags: string[];
};

const DEFAULT_TAG_SETTINGS: TagSettings = {
  stopwords: [
    "ve","veya","ile","ama","fakat","ancak","çok","daha","en","bir","bu","şu","o",
    "da","de","ki","mi","mu","mı","mü","için","gibi","kadar","sonra","önce",
    "ben","sen","o","biz","siz","onlar","şey","şimdi","yani"
  ],
  suffixes: ["lar","ler","dir","dır","dur","dür"],
  bannedWords: [],
  tagMinLength: 3,
  tagMaxLength: 24,
  maxTags: 5,
  trendThreshold: 0,
  trendWindowHours: 0,
  enableBigrams: false,
  bigram: {
    minScore: 1,
    joinChar: "",
    allowList: [],
    denyList: [],
  },
};

function normalizeTR(s: string) {
  return (s || "")
    .toLowerCase()
    .replace(/ı/g, "i")
    .replace(/ğ/g, "g")
    .replace(/ü/g, "u")
    .replace(/ş/g, "s")
    .replace(/ö/g, "o")
    .replace(/ç/g, "c");
}

function toMillis(x: any): number {
  if (typeof x === "number" && Number.isFinite(x)) return x;
  if (typeof x === "string") {
    const n = Number(x);
    if (Number.isFinite(n)) return n;
  }
  if (x && typeof x === "object") {
    if (typeof x.toMillis === "function") return x.toMillis();
    if (typeof x._seconds === "number") return x._seconds * 1000;
    if (typeof x.seconds === "number") return x.seconds * 1000;
  }
  return Date.now();
}

function lowerTR(s: string) {
  return (s || "").toLocaleLowerCase("tr-TR");
}

function splitWords(text: string): string[] {
  const t = (text || "")
    .replace(/https?:\/\/\S+/g, " ")
    .replace(/['’]/g, " ")
    .replace(/[^\p{L}\p{N}_#]+/gu, " ")
    .trim();
  if (!t) return [];
  return t.split(/\s+/g).filter(Boolean);
}

function extractHashtags(caption: string): string[] {
  const tags = new Set<string>();
  const re = /#([\p{L}\p{N}_]{2,40})/gu;
  let m: RegExpExecArray | null;
  while ((m = re.exec(caption || ""))) {
    tags.add(lowerTR(m[1]));
  }
  return Array.from(tags);
}

function extractMentions(text: string): string[] {
  const tags = new Set<string>();
  const re = /@([\p{L}\p{N}_]{2,40})/gu;
  let m: RegExpExecArray | null;
  while ((m = re.exec(text || ""))) {
    tags.add(lowerTR(m[1]));
  }
  return Array.from(tags);
}

function isValidUserTag(w: string, cfg: TagSettings): boolean {
  if (!w) return false;
  if (w.length < cfg.tagMinLength || w.length > cfg.tagMaxLength) return false;
  if (cfg.bannedWords.includes(normalizeTR(w))) return false;
  if (/^\d+$/.test(w)) return false;
  return true;
}

function stripSuffixes(word: string, suffixes: string[]): string {
  for (const suf of suffixes) {
    if (suf.length < 2) continue;
    if (word.endsWith(suf) && word.length - suf.length >= 3) {
      return word.slice(0, -suf.length);
    }
  }
  return word;
}

function isValidTag(w: string, cfg: TagSettings): boolean {
  if (!w) return false;
  if (w.startsWith("#")) return false;
  if (w.length < cfg.tagMinLength || w.length > cfg.tagMaxLength) return false;
  if (cfg.bannedWords.includes(normalizeTR(w))) return false;
  if (cfg.stopwords.includes(normalizeTR(w))) return false;
  if (/^\d+$/.test(w)) return false;
  return true;
}

function startsWithUppercaseTR(word: string): boolean {
  if (!word) return false;
  const first = word[0];
  const upper = first.toLocaleUpperCase("tr-TR");
  const lower = first.toLocaleLowerCase("tr-TR");
  return first === upper && upper !== lower;
}

export async function getTagSettings(): Promise<TagSettings> {
  ensureAdmin();
  const db = getFirestore();

  const snap = await db.doc("adminConfig/tagSettings").get();
  if (!snap.exists) return DEFAULT_TAG_SETTINGS;

  const d = snap.data() || {};
  const suffixesRaw = Array.isArray(d.suffixes)
    ? d.suffixes.map((x: any) => normalizeTR(String(x)))
    : DEFAULT_TAG_SETTINGS.suffixes;
  const suffixes = suffixesRaw.filter((s: string) => s.length >= 2).slice(0, 4);
  const maxTags = Number(d.maxTags ?? DEFAULT_TAG_SETTINGS.maxTags);
  const tagMinLength = Number(d.tagMinLength ?? DEFAULT_TAG_SETTINGS.tagMinLength);
  const tagMaxLength = Number(d.tagMaxLength ?? DEFAULT_TAG_SETTINGS.tagMaxLength);
  return {
    stopwords: Array.isArray(d.stopwords) ? d.stopwords.map((x: any) => normalizeTR(String(x))) : DEFAULT_TAG_SETTINGS.stopwords,
    suffixes,
    bannedWords: Array.isArray(d.bannedWords) ? d.bannedWords.map((x: any) => normalizeTR(String(x))) : DEFAULT_TAG_SETTINGS.bannedWords,
    tagMinLength,
    tagMaxLength,
    maxTags: Number.isFinite(maxTags) && maxTags > 0 ? Math.min(10, Math.max(1, maxTags)) : DEFAULT_TAG_SETTINGS.maxTags,
    trendThreshold: Number(d.trendThreshold ?? DEFAULT_TAG_SETTINGS.trendThreshold),
    trendWindowHours: Number(d.trendWindowHours ?? DEFAULT_TAG_SETTINGS.trendWindowHours),
    enableBigrams: Boolean(d.enableBigrams ?? DEFAULT_TAG_SETTINGS.enableBigrams),
    bigram: {
      minScore: Number(d.bigram?.minScore ?? DEFAULT_TAG_SETTINGS.bigram.minScore),
      joinChar: String(d.bigram?.joinChar ?? DEFAULT_TAG_SETTINGS.bigram.joinChar),
      allowList: Array.isArray(d.bigram?.allowList) ? d.bigram.allowList : DEFAULT_TAG_SETTINGS.bigram.allowList,
      denyList: Array.isArray(d.bigram?.denyList) ? d.bigram.denyList : DEFAULT_TAG_SETTINGS.bigram.denyList,
    },
  };
}

export async function generatePostTags(input: GenerateTagsInput): Promise<GenerateTagsOutput> {
  const cfg = await getTagSettings();

  const caption = input.caption || "";

  // 1) user hashtags sadece caption’dan
  const userHashtags = extractHashtags(caption).filter((t) => isValidUserTag(t, cfg));
  const userSet = new Set(userHashtags);

  // 2) system tags - sadece ÖZEL İSİM (proper noun) + ağırlıklı skor
  const score = new Map<string, number>();
  const addTokens = (text: string, weight: number) => {
    const wordsRaw = splitWords(text);
    for (const w0 of wordsRaw) {
      if (w0.startsWith("#")) continue;
      if (!startsWithUppercaseTR(w0)) continue;
      const wClean = stripSuffixes(w0.replace(/^#+/, ""), cfg.suffixes);
      const w = lowerTR(wClean);
      if (!isValidTag(w, cfg)) continue;
      if (userSet.has(w)) continue;
      score.set(w, (score.get(w) || 0) + weight);
    }
  };

  addTokens(caption, 3);

  // 3) bigrams
  if (cfg.enableBigrams) {
    const cleaned = splitWords(caption)
      .filter(w => startsWithUppercaseTR(w))
      .map(w => lowerTR(stripSuffixes(w.replace(/^#+/, ""), cfg.suffixes)))
      .filter(w => isValidTag(w, cfg) && !userSet.has(w));

    const counts = new Map<string, number>();
    const joinChar = cfg.bigram.joinChar || "_";
    for (let i = 0; i < cleaned.length - 1; i++) {
      const bi = `${cleaned[i]}${joinChar}${cleaned[i + 1]}`;
      counts.set(bi, (counts.get(bi) || 0) + 1);
    }

    const allow = new Set<string>(
      (cfg.bigram.allowList || []).map((p) => `${normalizeTR(p[0])}${joinChar}${normalizeTR(p[1])}`)
    );
    const deny = new Set<string>(
      (cfg.bigram.denyList || []).map((p) => `${normalizeTR(p[0])}${joinChar}${normalizeTR(p[1])}`)
    );

    for (const [bi, count] of counts.entries()) {
      if (allow.size > 0 && !allow.has(bi)) continue;
      if (deny.has(bi)) continue;
      if (count < Math.max(1, cfg.bigram.minScore || 1)) continue;
      if (bi.length <= cfg.tagMaxLength + joinChar.length) {
        score.set(bi, (score.get(bi) || 0) + count);
      }
    }
  }

  // 4) limit
  const finalTags = Array.from(score.entries())
    .sort((a, b) => b[1] - a[1])
    .map(([tag]) => tag)
    .slice(0, cfg.maxTags);

  return { userHashtags, finalTags };
}

function generateTagsFromText(text: string, cfg: TagSettings, maxTags: number, exclude: Set<string>) {
  const score = new Map<string, number>();
  const wordsRaw = splitWords(text);
  for (const w0 of wordsRaw) {
    if (w0.startsWith("#")) continue;
    if (!startsWithUppercaseTR(w0)) continue;
    const wClean = stripSuffixes(w0.replace(/^#+/, ""), cfg.suffixes);
    const w = lowerTR(wClean);
    if (!isValidTag(w, cfg)) continue;
    if (exclude.has(w)) continue;
    score.set(w, (score.get(w) || 0) + 1);
  }
  return Array.from(score.entries())
    .sort((a, b) => b[1] - a[1])
    .map(([tag]) => tag)
    .slice(0, Math.max(0, maxTags));
}

export async function generateTagDetails(input: GenerateTagsInput): Promise<GenerateTagDetails> {
  const cfg = await getTagSettings();
  const caption = input.caption || "";

  const hashtags = extractHashtags(caption).filter((t) => isValidUserTag(t, cfg));
  const mentions = extractMentions(caption);

  const exclude = new Set<string>(hashtags);
  const captionTags = generateTagsFromText(caption, cfg, 5, exclude);
  return { hashtags, mentions, captionTags };
}

// Tag index yazımı (idempotent, postId bazlı)
export async function writeTagIndex(
  postId: string,
  tags: string[],
  meta: {
    authorId: string;
    type: string;
    visibility: string;
    status: string;
    hlsReady: boolean;
    createdAt: any;
    trendThreshold: number;
    trendWindowHours: number;
    hashtagTags?: string[];
  }
): Promise<void> {
  ensureAdmin();
  const db = getFirestore();

  const unique = Array.from(new Set(tags || []));
  const hashtagSet = new Set((meta.hashtagTags || []).map((x) => normalizeTR(String(x || ""))));
  const chunkSize = 200; // 200 tags => ~400 writes max

  for (let i = 0; i < unique.length; i += chunkSize) {
    const chunk = unique.slice(i, i + chunkSize);
    await db.runTransaction(async (tx) => {
      const now = FieldValue.serverTimestamp();
      const baseMs = toMillis(meta.createdAt);
      const tagPostRefs = chunk.map((tag) => db.doc(`tags/${tag}/posts/${postId}`));
      const postTagRefs = chunk.map((tag) => db.doc(`Posts/${postId}/tags/${tag}`));
      const postHashtagRefs = chunk.map((tag) => db.doc(`Posts/${postId}/hashtags/${tag}`));
      const tagPostSnaps = await tx.getAll(...tagPostRefs);

      for (let idx = 0; idx < chunk.length; idx++) {
        const tag = chunk[idx];
        const tagRef = db.doc(`tags/${tag}`);
        const tagPostSnap = tagPostSnaps[idx];
        const postTagRef = postTagRefs[idx];
        const postHashtagRef = postHashtagRefs[idx];
        const hasHashtag = hashtagSet.has(normalizeTR(tag));

        if (!tagPostSnap.exists) {
          tx.set(
            tagPostSnap.ref,
            {
              postId,
              createdAt: meta.createdAt,
              authorId: meta.authorId,
              type: meta.type,
              visibility: meta.visibility,
              status: meta.status,
              hlsReady: meta.hlsReady,
              hasHashtag,
            },
            { merge: true }
          );
          tx.set(
            hasHashtag ? postHashtagRef : postTagRef,
            {
              tag,
              postId,
              hasHashtag,
              updatedAt: now,
            },
            { merge: true }
          );
          tx.delete(hasHashtag ? postTagRef : postHashtagRef);
          tx.set(
            tagRef,
            {
              name: tag,
              count: FieldValue.increment(1),
              hashtagCount: FieldValue.increment(hasHashtag ? 1 : 0),
              plainCount: FieldValue.increment(hasHashtag ? 0 : 1),
              hasHashtag: hasHashtag ? true : FieldValue.delete(),
              lastSeenAt: baseMs,
              trendThreshold: meta.trendThreshold,
              trendWindowHours: meta.trendWindowHours,
            },
            { merge: true }
          );
        } else {
          const prevHasHashtag = tagPostSnap.get("hasHashtag") === true;
          const hashtagDelta = hasHashtag === prevHasHashtag ? 0 : hasHashtag ? 1 : -1;
          const plainDelta = hasHashtag === prevHasHashtag ? 0 : hasHashtag ? -1 : 1;
          tx.set(
            tagRef,
            {
              lastSeenAt: baseMs,
              ...(hashtagDelta !== 0 ? { hashtagCount: FieldValue.increment(hashtagDelta) } : {}),
              ...(plainDelta !== 0 ? { plainCount: FieldValue.increment(plainDelta) } : {}),
              hasHashtag: hasHashtag ? true : FieldValue.delete(),
            },
            { merge: true }
          );
          tx.set(
            tagPostSnap.ref,
            {
              hasHashtag,
            },
            { merge: true }
          );
          tx.set(
            hasHashtag ? postHashtagRef : postTagRef,
            {
              tag,
              postId,
              hasHashtag,
              updatedAt: now,
            },
            { merge: true }
          );
          tx.delete(hasHashtag ? postTagRef : postHashtagRef);
        }
      }
    });
  }
}
