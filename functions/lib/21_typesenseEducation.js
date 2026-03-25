"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.f21_reindexEducationToTypesenseCallable = exports.f21_searchEducationCallable = exports.f21_ensureEducationTypesenseCollectionCallable = exports.f21_syncPastQuestionsToTypesense = exports.f21_syncWorkoutsToTypesense = exports.f21_syncJobsToTypesense = exports.f21_syncTutoringsToTypesense = exports.f21_syncAnswerKeysToTypesense = exports.f21_syncPracticeExamsToTypesense = exports.f21_syncScholarshipsToTypesense = void 0;
const firestore_1 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const app_1 = require("firebase-admin/app");
const firestore_2 = require("firebase-admin/firestore");
const axios_1 = require("axios");
const rateLimiter_1 = require("./rateLimiter");
const REGION = getEnv("TYPESENSE_REGION") || "us-central1";
const MAX_LIMIT = 100;
const MAX_DETAILS_TEXT_LEN = 24000;
const MAX_DETAILS_JSON_LEN = 32000;
const MAX_INDEX_DEPTH = 4;
const MAX_INDEX_ARRAY = 20;
const MAX_INDEX_OBJECT_KEYS = 120;
const NOISY_DETAIL_KEYS = new Set([
    "kaydedenler",
    "kaydedilenler",
    "begeniler",
    "goruntuleme",
    "basvurular",
    "token",
    "fcmToken",
    "fcm_token",
    "sifre",
    "password",
    "iban",
    "tc",
    "phoneNumber",
    "email",
    "mail",
    "device",
    "deviceID",
    "deviceVersion",
    "authorAvatarUrl",
    "authorDisplayName",
    "authorNickname",
    "avatarUrl",
    "displayName",
    "nickname",
    "logo",
    "cover",
    "updatedAt",
    "timeStamp",
    "userID",
    "viewCount",
    "applicationCount",
    "endedAt",
    "lat",
    "long",
    "dogruCevap",
]);
const EDUCATION_ENTITIES = [
    "scholarship",
    "practice_exam",
    "answer_key",
    "tutoring",
    "job",
    "workout",
    "past_question",
];
const EDUCATION_COLLECTIONS = {
    scholarship: "education_scholarships_search",
    practice_exam: "education_online_exams_search",
    answer_key: "education_answer_keys_search",
    tutoring: "education_tutoring_search",
    job: "education_jobs_search",
    workout: "education_workouts_search",
    past_question: "education_past_questions_search",
};
const JOB_TYPESENSE_REDUCED_FIELDS = new Set([
    "authorNickname",
    "authorDisplayName",
    "authorAvatarUrl",
    "detailsJson",
    "logo",
]);
const SCHOLARSHIP_TYPESENSE_REDUCED_FIELDS = new Set([
    "authorNickname",
    "authorDisplayName",
    "authorAvatarUrl",
    "detailsJson",
    "img",
]);
const TUTORING_TYPESENSE_REDUCED_FIELDS = new Set([
    "authorNickname",
    "authorDisplayName",
    "authorAvatarUrl",
    "shortDescription",
    "img2",
    "baslangicTarihi",
    "bitisTarihi",
    "basvuruKosullari",
    "basvuruURL",
    "basvuruYapilacakYer",
    "bursVeren",
    "egitimKitlesi",
    "geriOdemeli",
    "hedefKitle",
    "mukerrerDurumu",
    "ogrenciSayisi",
    "tutar",
    "website",
    "lisansTuru",
    "template",
    "ulke",
    "altEgitimKitlesi",
    "aylar",
    "belgeler",
    "sehirler",
    "ilceler",
    "universiteler",
    "liseOrtaOkulIlceler",
    "liseOrtaOkulSehirler",
    "likeCount",
    "bookmarkCount",
    "detailsJson",
    "brand",
    "yanHaklar",
    "calismaGunleri",
    "calismaSaatiBaslangic",
    "calismaSaatiBitis",
    "calismaTuru",
    "isTanimi",
    "adres",
    "maas1",
    "maas2",
    "meslek",
    "ilanBasligi",
    "deneyimSeviyesi",
    "basvuruSayisi",
    "pozisyonSayisi",
    "about",
]);
function ensureAdmin() {
    if ((0, app_1.getApps)().length === 0)
        (0, app_1.initializeApp)();
}
function requireAuth(request) {
    const uid = request.auth?.uid;
    if (!uid) {
        throw new https_1.HttpsError("unauthenticated", "auth_required");
    }
    return uid;
}
function requireAdminAuth(request) {
    const uid = requireAuth(request);
    const token = request.auth?.token;
    if (token?.admin !== true) {
        throw new https_1.HttpsError("permission-denied", "admin_required");
    }
    rateLimiter_1.RateLimits.admin(uid);
    return uid;
}
function getEnv(name) {
    return String(process.env[name] || "").trim();
}
function getTypesenseBaseUrl() {
    const raw = getEnv("TYPESENSE_HOST");
    if (!raw)
        return "";
    const hasProtocol = raw.startsWith("http://") || raw.startsWith("https://");
    return (hasProtocol ? raw : `https://${raw}`).replace(/\/+$/g, "");
}
function getTypesenseApiKey() {
    return getEnv("TYPESENSE_API_KEY");
}
function typesenseReady() {
    return !!getTypesenseBaseUrl() && !!getTypesenseApiKey();
}
function headers() {
    return {
        "X-TYPESENSE-API-KEY": getTypesenseApiKey(),
        "Content-Type": "application/json",
    };
}
function asString(x) {
    return typeof x === "string" ? x.trim() : "";
}
function asBool(x) {
    return x === true;
}
function asStringArray(x) {
    if (!Array.isArray(x))
        return [];
    return x.map((v) => String(v ?? "").trim()).filter((v) => v.length > 0);
}
function firstString(x) {
    return asStringArray(x)[0] || "";
}
function asEpochSeconds(x) {
    if (!x)
        return 0;
    if (typeof x === "number" && Number.isFinite(x)) {
        return x > 1e12 ? Math.floor(x / 1000) : Math.floor(x);
    }
    if (typeof x === "object" && x !== null) {
        const maybe = x;
        if (typeof maybe.seconds === "number")
            return Math.floor(maybe.seconds);
        if (typeof maybe._seconds === "number")
            return Math.floor(maybe._seconds);
        if (typeof maybe.toMillis === "function") {
            const ms = maybe.toMillis();
            if (Number.isFinite(ms))
                return Math.floor(ms / 1000);
        }
    }
    return 0;
}
function asEpochMillis(x) {
    const sec = asEpochSeconds(x);
    if (sec > 0)
        return sec * 1000;
    if (typeof x === "number" && Number.isFinite(x))
        return Math.floor(x);
    if (typeof x === "string") {
        const n = Number(x);
        if (Number.isFinite(n))
            return Math.floor(n);
    }
    return 0;
}
function asInt(x) {
    if (typeof x === "number" && Number.isFinite(x))
        return Math.floor(x);
    if (typeof x === "string") {
        const n = Number(x);
        if (Number.isFinite(n))
            return Math.floor(n);
    }
    return 0;
}
function asFloat(x) {
    if (typeof x === "number" && Number.isFinite(x))
        return x;
    if (typeof x === "string") {
        const n = Number(x);
        if (Number.isFinite(n))
            return n;
    }
    return 0;
}
function dedupe(values) {
    const out = new Set();
    for (const value of values) {
        const t = value.trim();
        if (t)
            out.add(t);
    }
    return Array.from(out);
}
function composeDescription(...parts) {
    const merged = dedupe(parts.map((x) => x.trim()).filter((x) => x.length > 0)).join(" | ");
    return truncateText(merged, 8000);
}
function truncateText(value, maxLen) {
    return value.length <= maxLen ? value : value.slice(0, maxLen);
}
function flattenForSearch(value, out, depth = 0) {
    if (depth > MAX_INDEX_DEPTH || out.length > 1200)
        return;
    if (value === null || value === undefined)
        return;
    if (typeof value === "string") {
        const t = value.trim();
        if (t)
            out.push(truncateText(t, 300));
        return;
    }
    if (typeof value === "number" || typeof value === "boolean") {
        out.push(String(value));
        return;
    }
    if (Array.isArray(value)) {
        for (const item of value.slice(0, MAX_INDEX_ARRAY)) {
            flattenForSearch(item, out, depth + 1);
            if (out.length > 1200)
                return;
        }
        return;
    }
    if (typeof value === "object") {
        const entries = Object.entries(value).slice(0, MAX_INDEX_OBJECT_KEYS);
        for (const [key, v] of entries) {
            const keyText = key.trim();
            if (keyText)
                out.push(keyText);
            flattenForSearch(v, out, depth + 1);
            if (out.length > 1200)
                return;
        }
    }
}
function isNoisyDetailKey(keyRaw) {
    const key = keyRaw.trim();
    if (!key)
        return true;
    if (NOISY_DETAIL_KEYS.has(key))
        return true;
    if (/^(img\d+|image\d+|photo\d+)$/i.test(key))
        return true;
    return false;
}
function pruneForSearch(value, depth = 0) {
    if (value === undefined || value === null)
        return undefined;
    if (depth > MAX_INDEX_DEPTH)
        return undefined;
    if (typeof value === "string") {
        const text = value.trim();
        if (!text)
            return undefined;
        if (/^https?:\/\//i.test(text))
            return undefined;
        return truncateText(text, 500);
    }
    if (typeof value === "number" || typeof value === "boolean") {
        return value;
    }
    if (Array.isArray(value)) {
        const items = value
            .slice(0, MAX_INDEX_ARRAY)
            .map((item) => pruneForSearch(item, depth + 1))
            .filter((item) => item !== undefined);
        return items.length ? items : undefined;
    }
    if (typeof value === "object") {
        const out = {};
        const entries = Object.entries(value).slice(0, MAX_INDEX_OBJECT_KEYS);
        for (const [key, raw] of entries) {
            if (isNoisyDetailKey(key))
                continue;
            const clean = pruneForSearch(raw, depth + 1);
            if (clean !== undefined)
                out[key] = clean;
        }
        return Object.keys(out).length ? out : undefined;
    }
    return undefined;
}
function buildDetailsText(data) {
    const flattened = [];
    flattenForSearch(pruneForSearch(data), flattened);
    const normalized = dedupe(flattened);
    return truncateText(normalized.join(" "), MAX_DETAILS_TEXT_LEN);
}
function safeStringify(value) {
    try {
        const raw = JSON.stringify(value);
        if (!raw)
            return "";
        return truncateText(raw, MAX_DETAILS_JSON_LEN);
    }
    catch {
        return "";
    }
}
function isEducationEntity(value) {
    return EDUCATION_ENTITIES.includes(value);
}
function getCollectionName(entity) {
    return EDUCATION_COLLECTIONS[entity];
}
const ensureCollectionPromises = {};
function requiredFields(entity) {
    const fields = [
        { name: "docId", type: "string", optional: true },
        { name: "entity", type: "string" },
        { name: "title", type: "string", optional: true },
        { name: "subtitle", type: "string", optional: true },
        { name: "description", type: "string", optional: true },
        { name: "ownerId", type: "string", optional: true },
        { name: "timeStamp", type: "int64", optional: false },
        { name: "active", type: "bool", optional: true },
        { name: "city", type: "string", optional: true },
        { name: "town", type: "string", optional: true },
        { name: "country", type: "string", optional: true },
        { name: "tags", type: "string[]", optional: true },
        { name: "cover", type: "string", optional: true },
        { name: "logo", type: "string", optional: true },
        { name: "nickname", type: "string", optional: true },
        { name: "displayName", type: "string", optional: true },
        { name: "avatarUrl", type: "string", optional: true },
        { name: "rozet", type: "string", optional: true },
        { name: "shortDescription", type: "string", optional: true },
        { name: "aciklama", type: "string", optional: true },
        { name: "img2", type: "string", optional: true },
        { name: "baslangicTarihi", type: "string", optional: true },
        { name: "bitisTarihi", type: "string", optional: true },
        { name: "basvuruKosullari", type: "string", optional: true },
        { name: "basvuruURL", type: "string", optional: true },
        { name: "basvuruYapilacakYer", type: "string", optional: true },
        { name: "bursVeren", type: "string", optional: true },
        { name: "egitimKitlesi", type: "string", optional: true },
        { name: "geriOdemeli", type: "string", optional: true },
        { name: "hedefKitle", type: "string", optional: true },
        { name: "mukerrerDurumu", type: "string", optional: true },
        { name: "ogrenciSayisi", type: "string", optional: true },
        { name: "tutar", type: "string", optional: true },
        { name: "website", type: "string", optional: true },
        { name: "lisansTuru", type: "string", optional: true },
        { name: "template", type: "string", optional: true },
        { name: "ulke", type: "string", optional: true },
        { name: "altEgitimKitlesi", type: "string[]", optional: true },
        { name: "aylar", type: "string[]", optional: true },
        { name: "belgeler", type: "string[]", optional: true },
        { name: "sehirler", type: "string[]", optional: true },
        { name: "ilceler", type: "string[]", optional: true },
        { name: "universiteler", type: "string[]", optional: true },
        { name: "liseOrtaOkulIlceler", type: "string[]", optional: true },
        { name: "liseOrtaOkulSehirler", type: "string[]", optional: true },
        { name: "likeCount", type: "int32", optional: true },
        { name: "bookmarkCount", type: "int32", optional: true },
        { name: "detailsText", type: "string", optional: true },
        { name: "brand", type: "string", optional: true },
        { name: "yanHaklar", type: "string[]", optional: true },
        { name: "calismaGunleri", type: "string[]", optional: true },
        { name: "calismaSaatiBaslangic", type: "string", optional: true },
        { name: "calismaSaatiBitis", type: "string", optional: true },
        { name: "calismaTuru", type: "string[]", optional: true },
        { name: "ended", type: "bool", optional: true },
        { name: "isTanimi", type: "string", optional: true },
        { name: "lat", type: "float", optional: true },
        { name: "long", type: "float", optional: true },
        { name: "adres", type: "string", optional: true },
        { name: "maas1", type: "int64", optional: true },
        { name: "maas2", type: "int64", optional: true },
        { name: "meslek", type: "string", optional: true },
        { name: "ilanBasligi", type: "string", optional: true },
        { name: "deneyimSeviyesi", type: "string", optional: true },
        { name: "basvuruSayisi", type: "int32", optional: true },
        { name: "pozisyonSayisi", type: "int32", optional: true },
        { name: "viewCount", type: "int32", optional: true },
        { name: "applicationCount", type: "int32", optional: true },
        { name: "endedAt", type: "int64", optional: true },
        { name: "about", type: "string", optional: true },
        { name: "categoryKey", type: "string", optional: true },
        { name: "anaBaslik", type: "string", optional: true },
        { name: "baslik2", type: "string", optional: true },
        { name: "baslik3", type: "string", optional: true },
        { name: "dil", type: "string", optional: true },
        { name: "ders", type: "string", optional: true },
        { name: "sinavTuru", type: "string", optional: true },
        { name: "soruNo", type: "string", optional: true },
        { name: "yil", type: "string", optional: true },
        { name: "seq", type: "int32", optional: true },
        { name: "correctCount", type: "int32", optional: true },
        { name: "wrongCount", type: "int32", optional: true },
        { name: "soru", type: "string", optional: true },
        { name: "dogruCevap", type: "string", optional: true },
        { name: "kacCevap", type: "int32", optional: true },
        { name: "diger1", type: "string", optional: true },
        { name: "diger2", type: "bool", optional: true },
        { name: "diger3", type: "float", optional: true },
    ];
    if (entity === "job") {
        return fields.filter((field) => !JOB_TYPESENSE_REDUCED_FIELDS.has(field.name));
    }
    if (entity === "scholarship") {
        return fields.filter((field) => !SCHOLARSHIP_TYPESENSE_REDUCED_FIELDS.has(field.name));
    }
    if (entity === "tutoring") {
        return fields.filter((field) => !TUTORING_TYPESENSE_REDUCED_FIELDS.has(field.name));
    }
    return fields;
}
async function ensureEntityCollection(entity) {
    if (ensureCollectionPromises[entity])
        return ensureCollectionPromises[entity];
    ensureCollectionPromises[entity] = (async () => {
        const baseUrl = getTypesenseBaseUrl();
        if (!baseUrl)
            return;
        const collection = getCollectionName(entity);
        try {
            const existing = await axios_1.default.get(`${baseUrl}/collections/${collection}`, {
                headers: headers(),
                timeout: 8000,
            });
            const fields = Array.isArray(existing.data?.fields)
                ? existing.data.fields
                : [];
            const missing = requiredFields(entity).filter((rf) => !fields.some((f) => f?.name === rf.name));
            if (missing.length) {
                await axios_1.default.patch(`${baseUrl}/collections/${collection}`, { fields: missing }, { headers: headers(), timeout: 8000 });
            }
            return;
        }
        catch (err) {
            const status = err?.response?.status;
            if (status !== 404)
                throw err;
        }
        await axios_1.default.post(`${baseUrl}/collections`, {
            name: collection,
            fields: requiredFields(entity),
            default_sorting_field: "timeStamp",
        }, { headers: headers(), timeout: 8000 });
    })().catch((err) => {
        ensureCollectionPromises[entity] = undefined;
        throw err;
    });
    return ensureCollectionPromises[entity];
}
async function ensureAllEntityCollections() {
    await Promise.all(EDUCATION_ENTITIES.map((entity) => ensureEntityCollection(entity)));
}
async function upsertDoc(entity, doc) {
    const baseUrl = getTypesenseBaseUrl();
    if (!baseUrl)
        return;
    const collection = getCollectionName(entity);
    await ensureEntityCollection(entity);
    await axios_1.default.post(`${baseUrl}/collections/${collection}/documents?action=upsert`, doc, { headers: headers(), timeout: 12000 });
}
async function deleteDoc(entity, docId) {
    const baseUrl = getTypesenseBaseUrl();
    if (!baseUrl)
        return;
    const collection = getCollectionName(entity);
    await ensureEntityCollection(entity);
    try {
        await axios_1.default.delete(`${baseUrl}/collections/${collection}/documents/${encodeURIComponent(docId)}`, { headers: headers(), timeout: 12000 });
    }
    catch (err) {
        const status = err?.response?.status;
        if (status === 404)
            return;
        throw err;
    }
}
function baseDoc(entity, docId, data, partial) {
    const pruned = pruneForSearch(data);
    return {
        id: docId,
        docId,
        entity,
        title: partial.title.trim(),
        subtitle: partial.subtitle?.trim() || "",
        description: partial.description?.trim() || "",
        ownerId: partial.ownerId?.trim() || "",
        timeStamp: partial.timeStamp && partial.timeStamp > 0 ? partial.timeStamp : Date.now(),
        active: partial.active === false ? false : true,
        city: partial.city?.trim() || "",
        town: partial.town?.trim() || "",
        country: partial.country?.trim() || "",
        tags: dedupe(partial.tags || []),
        cover: partial.cover?.trim() || "",
        detailsText: buildDetailsText(data),
        detailsJson: safeStringify(pruned),
    };
}
async function fetchAuthorSummary(userId) {
    const normalizedUserId = asString(userId);
    if (!normalizedUserId) {
        return {
            nickname: "",
            displayName: "",
            avatarUrl: "",
            rozet: "",
        };
    }
    try {
        const snap = await (0, firestore_2.getFirestore)().collection("users").doc(normalizedUserId).get();
        if (!snap.exists) {
            return {
                nickname: "",
                displayName: "",
                avatarUrl: "",
                rozet: "",
            };
        }
        const data = (snap.data() || {});
        const nickname = asString(data.nickname) || asString(data.username);
        const displayName = asString(data.displayName) ||
            asString(data.fullName) ||
            [asString(data.firstName), asString(data.lastName)]
                .filter(Boolean)
                .join(" ")
                .trim() ||
            nickname;
        return {
            nickname,
            displayName,
            avatarUrl: asString(data.avatarUrl) ||
                asString(data.photoUrl) ||
                asString(data.profileImage) ||
                asString(data.imageUrl),
            rozet: asString(data.rozet),
        };
    }
    catch (err) {
        console.error("typesense_education_author_summary_fetch_failed", normalizedUserId, err);
        return {
            nickname: "",
            displayName: "",
            avatarUrl: "",
            rozet: "",
        };
    }
}
function buildScholarshipDoc(docId, data) {
    const description = composeDescription(asString(data.shortDescription), asString(data.aciklama), asString(data.basvuruKosullari), asString(data.basvuruYapilacakYer), asString(data.basvuruURL), asString(data.website), asString(data.baslangicTarihi), asString(data.bitisTarihi));
    const base = baseDoc("scholarship", docId, data, {
        title: asString(data.baslik),
        subtitle: asString(data.bursVeren),
        description,
        ownerId: asString(data.userID),
        timeStamp: asEpochMillis(data.timeStamp),
        active: true,
        city: firstString(data.sehirler),
        town: firstString(data.ilceler),
        country: asString(data.ulke),
        tags: dedupe([
            asString(data.bursVeren),
            asString(data.egitimKitlesi),
            asString(data.lisansTuru),
            ...asStringArray(data.sehirler),
            ...asStringArray(data.ilceler),
            ...asStringArray(data.universiteler),
            ...asStringArray(data.tags),
        ]),
        cover: asString(data.img) || asString(data.logo),
    });
    const nickname = asString(data.nickname) || asString(data.authorNickname);
    const displayName = asString(data.displayName) ||
        asString(data.authorDisplayName) ||
        nickname;
    const avatarUrl = asString(data.avatarUrl) || asString(data.authorAvatarUrl);
    const begeniler = asStringArray(data.begeniler);
    const kaydedenler = asStringArray(data.kaydedenler);
    const { detailsJson: _detailsJson, ...rest } = base;
    return {
        ...rest,
        nickname,
        displayName,
        avatarUrl,
        rozet: asString(data.rozet),
        logo: asString(data.logo),
        shortDescription: asString(data.shortDescription),
        aciklama: asString(data.aciklama),
        img2: asString(data.img2),
        baslangicTarihi: asString(data.baslangicTarihi),
        bitisTarihi: asString(data.bitisTarihi),
        basvuruKosullari: asString(data.basvuruKosullari),
        basvuruURL: asString(data.basvuruURL),
        basvuruYapilacakYer: asString(data.basvuruYapilacakYer),
        bursVeren: asString(data.bursVeren),
        egitimKitlesi: asString(data.egitimKitlesi),
        geriOdemeli: asString(data.geriOdemeli),
        hedefKitle: asString(data.hedefKitle),
        mukerrerDurumu: asString(data.mukerrerDurumu),
        ogrenciSayisi: asString(data.ogrenciSayisi),
        tutar: asString(data.tutar),
        website: asString(data.website),
        lisansTuru: asString(data.lisansTuru),
        template: asString(data.template),
        ulke: asString(data.ulke),
        altEgitimKitlesi: asStringArray(data.altEgitimKitlesi),
        aylar: asStringArray(data.aylar),
        belgeler: asStringArray(data.belgeler),
        sehirler: asStringArray(data.sehirler),
        ilceler: asStringArray(data.ilceler),
        universiteler: asStringArray(data.universiteler),
        liseOrtaOkulIlceler: asStringArray(data.liseOrtaOkulIlceler),
        liseOrtaOkulSehirler: asStringArray(data.liseOrtaOkulSehirler),
        likeCount: asInt(data.likesCount) || begeniler.length,
        bookmarkCount: asInt(data.bookmarksCount) || kaydedenler.length,
    };
}
function buildPracticeExamDoc(docId, data) {
    const isPublic = data.public === undefined ? true : asBool(data.public);
    const isDraft = asBool(data.taslak);
    return baseDoc("practice_exam", docId, data, {
        title: asString(data.sinavAdi),
        subtitle: asString(data.sinavTuru),
        description: asString(data.sinavAciklama),
        ownerId: asString(data.userID),
        timeStamp: asEpochMillis(data.timeStamp),
        active: isPublic && !isDraft,
        tags: dedupe([
            asString(data.sinavTuru),
            ...asStringArray(data.dersler),
            asString(data.kpssSecilenLisans),
            ...asStringArray(data.tags),
        ]),
        cover: asString(data.cover),
    });
}
function buildAnswerKeyDoc(docId, data) {
    return baseDoc("answer_key", docId, data, {
        title: asString(data.baslik),
        subtitle: asString(data.yayinEvi),
        description: asString(data.sinavTuru),
        ownerId: asString(data.userID),
        timeStamp: asEpochMillis(data.timeStamp),
        active: true,
        tags: dedupe([
            asString(data.sinavTuru),
            asString(data.dil),
            asString(data.yayinEvi),
            ...asStringArray(data.tags),
        ]),
        cover: asString(data.cover),
    });
}
function buildTutoringDoc(docId, data) {
    const imgs = asStringArray(data.imgs);
    const description = composeDescription(asString(data.aciklama), asString(data.detay), asString(data.ekAciklama), asString(data.ucret), ...asStringArray(data.dersYeri));
    const base = baseDoc("tutoring", docId, data, {
        title: asString(data.baslik),
        subtitle: asString(data.brans),
        description,
        ownerId: asString(data.userID) || asString(data.userId),
        timeStamp: asEpochMillis(data.timeStamp),
        active: !asBool(data.ended),
        city: asString(data.sehir),
        town: asString(data.ilce),
        tags: dedupe([
            asString(data.brans),
            ...asStringArray(data.dersYeri),
            asString(data.cinsiyet),
            ...asStringArray(data.tags),
        ]),
        cover: imgs[0] || "",
    });
    const { detailsJson: _detailsJson, ...rest } = base;
    return {
        ...rest,
        aciklama: asString(data.aciklama),
        dersYeri: asStringArray(data.dersYeri),
        cinsiyet: asString(data.cinsiyet),
        fiyat: asInt(data.fiyat),
        telefon: asBool(data.telefon),
        whatsapp: asBool(data.whatsapp),
        averageRating: asFloat(data.averageRating),
        reviewCount: asInt(data.reviewCount),
        ended: asBool(data.ended),
        endedAt: asInt(data.endedAt),
        viewCount: asInt(data.viewCount),
        applicationCount: asInt(data.applicationCount),
        lat: asFloat(data.lat),
        long: asFloat(data.long),
    };
}
function buildJobDoc(docId, data) {
    const imgs = asStringArray(data.imgs);
    const title = asString(data.ilanBasligi) || asString(data.meslek) || asString(data.brand);
    const description = composeDescription(asString(data.isTanimi), asString(data.ilanDetayi), asString(data.aciklama), asString(data.arananNitelikler), ...asStringArray(data.yanHaklar), ...asStringArray(data.calismaTuru));
    const base = baseDoc("job", docId, data, {
        title,
        subtitle: asString(data.brand),
        description,
        ownerId: asString(data.userID),
        timeStamp: asEpochMillis(data.timeStamp),
        active: !asBool(data.ended),
        city: asString(data.city),
        town: asString(data.town),
        tags: dedupe([
            asString(data.meslek),
            asString(data.deneyimSeviyesi),
            ...asStringArray(data.calismaGunleri),
            ...asStringArray(data.calismaTuru),
            ...asStringArray(data.yanHaklar),
            ...asStringArray(data.tags),
        ]),
        cover: asString(data.logo) || imgs[0] || "",
    });
    const { detailsJson: _detailsJson, ...rest } = base;
    return rest;
}
function buildWorkoutDoc(docId, data) {
    const anaBaslik = asString(data.anaBaslik);
    const sinavTuru = asString(data.sinavTuru);
    const ders = asString(data.ders);
    const soruNo = asString(data.soruNo);
    const yil = asString(data.yil);
    const title = asString(data.title) ||
        asString(data.baslik) ||
        composeDescription(anaBaslik, sinavTuru, ders).split(" | ").join(" - ");
    const subtitle = composeDescription(ders, sinavTuru, soruNo && yil ? `Soru ${soruNo} • ${yil}` : `Soru ${soruNo}`);
    const description = asString(data.aciklama) ||
        composeDescription(anaBaslik, sinavTuru, ders, soruNo.length === 0 ? "" : `Soru ${soruNo}`, yil);
    const base = baseDoc("workout", docId, data, {
        title,
        subtitle,
        description,
        ownerId: asString(data.userID) || asString(data.ownerId),
        timeStamp: asEpochMillis(data.timeStamp) || asEpochMillis(data.createdDate),
        active: data.active ?? (asBool(data.iptal) ? false : !asBool(data.deleted)),
        tags: dedupe([
            anaBaslik,
            sinavTuru,
            ders,
            yil,
            asString(data.konu),
            asString(data.sinif),
            ...asStringArray(data.tags),
        ]),
        cover: asString(data.soru) || asString(data.cover) || asString(data.img),
    });
    return {
        ...base,
        categoryKey: asString(data.categoryKey),
        anaBaslik,
        ders,
        sinavTuru,
        soruNo,
        yil,
        seq: asInt(data.seq),
        correctCount: asInt(data.correctCount),
        wrongCount: asInt(data.wrongCount),
        viewCount: asInt(data.viewCount),
        soru: asString(data.soru),
        dogruCevap: asString(data.dogruCevap),
        kacCevap: asInt(data.kacCevap),
        diger1: asString(data.diger1),
        diger2: asBool(data.diger2),
        diger3: asFloat(data.diger3),
    };
}
function buildPastQuestionDoc(docId, data) {
    const anaBaslik = asString(data.anaBaslik);
    const baslik2 = asString(data.baslik2);
    const baslik3 = asString(data.baslik3);
    const sinavTuru = asString(data.sinavTuru);
    const yil = asString(data.yil);
    const dil = asString(data.dil);
    const title = asString(data.title) ||
        composeDescription(anaBaslik, sinavTuru, yil).split(" | ").join(" - ");
    const subtitle = composeDescription(baslik2, baslik3, dil);
    const description = composeDescription(asString(data.aciklama), anaBaslik, sinavTuru, yil, baslik2, baslik3, dil);
    const base = baseDoc("past_question", docId, data, {
        title,
        subtitle,
        description,
        ownerId: asString(data.userID) || asString(data.ownerId),
        timeStamp: asEpochMillis(data.timeStamp) || asEpochMillis(data.createdDate),
        active: data.active ?? (asBool(data.iptal) ? false : !asBool(data.deleted)),
        tags: dedupe([
            anaBaslik,
            sinavTuru,
            yil,
            baslik2,
            baslik3,
            dil,
            ...asStringArray(data.tags),
        ]),
        cover: asString(data.cover) || asString(data.soru) || asString(data.img),
    });
    return {
        ...base,
        anaBaslik,
        baslik2,
        baslik3,
        dil,
        sinavTuru,
        yil,
        seq: asInt(data.sira),
    };
}
function buildSearchDoc(entity, docId, data) {
    switch (entity) {
        case "scholarship":
            return buildScholarshipDoc(docId, data);
        case "practice_exam":
            return buildPracticeExamDoc(docId, data);
        case "answer_key":
            return buildAnswerKeyDoc(docId, data);
        case "tutoring":
            return buildTutoringDoc(docId, data);
        case "job":
            return buildJobDoc(docId, data);
        case "workout":
            return buildWorkoutDoc(docId, data);
        case "past_question":
            return buildPastQuestionDoc(docId, data);
    }
}
async function buildSearchDocForIndexing(entity, docId, data) {
    const doc = buildSearchDoc(entity, docId, data);
    if (entity === "scholarship") {
        const summary = await fetchAuthorSummary(doc.ownerId || "");
        const nickname = doc.nickname ||
            asString(data.nickname) ||
            asString(data.authorNickname) ||
            summary.nickname;
        const displayName = doc.displayName ||
            asString(data.displayName) ||
            asString(data.authorDisplayName) ||
            summary.displayName ||
            nickname;
        const avatarUrl = doc.avatarUrl ||
            asString(data.avatarUrl) ||
            asString(data.authorAvatarUrl) ||
            summary.avatarUrl;
        const rozet = doc.rozet ||
            asString(data.rozet) ||
            summary.rozet;
        return {
            ...doc,
            nickname,
            displayName,
            avatarUrl,
            rozet,
        };
    }
    if (entity === "tutoring") {
        const summary = await fetchAuthorSummary(doc.ownerId || "");
        const nickname = doc.nickname ||
            asString(data.nickname) ||
            summary.nickname;
        const displayName = doc.displayName ||
            asString(data.displayName) ||
            summary.displayName ||
            nickname;
        const avatarUrl = asString(data.avatarUrl) ||
            doc.avatarUrl ||
            summary.avatarUrl;
        const rozet = doc.rozet || asString(data.rozet) || summary.rozet;
        return {
            ...doc,
            nickname,
            displayName,
            avatarUrl,
            rozet,
            aciklama: asString(data.aciklama),
            dersYeri: asStringArray(data.dersYeri),
            cinsiyet: asString(data.cinsiyet),
            fiyat: asInt(data.fiyat),
            telefon: asBool(data.telefon),
            whatsapp: asBool(data.whatsapp),
            averageRating: asFloat(data.averageRating),
            reviewCount: asInt(data.reviewCount),
            ended: asBool(data.ended),
            endedAt: asInt(data.endedAt),
            viewCount: asInt(data.viewCount),
            applicationCount: asInt(data.applicationCount),
            lat: asFloat(data.lat),
            long: asFloat(data.long),
        };
    }
    if (entity !== "job")
        return doc;
    const summary = await fetchAuthorSummary(doc.ownerId || "");
    const nickname = doc.nickname || asString(data.nickname) || summary.nickname;
    const displayName = doc.displayName ||
        asString(data.displayName) ||
        summary.displayName ||
        nickname;
    const avatarUrl = asString(data.avatarUrl) ||
        doc.avatarUrl ||
        summary.avatarUrl;
    const rozet = doc.rozet || asString(data.rozet) || summary.rozet;
    return {
        ...doc,
        nickname,
        displayName,
        avatarUrl,
        rozet,
        brand: asString(data.brand),
        yanHaklar: asStringArray(data.yanHaklar),
        calismaGunleri: asStringArray(data.calismaGunleri),
        calismaSaatiBaslangic: asString(data.calismaSaatiBaslangic),
        calismaSaatiBitis: asString(data.calismaSaatiBitis),
        calismaTuru: asStringArray(data.calismaTuru),
        ended: asBool(data.ended),
        isTanimi: asString(data.isTanimi),
        lat: Number(data.lat || 0),
        long: Number(data.long || 0),
        adres: asString(data.adres),
        maas1: asInt(data.maas1),
        maas2: asInt(data.maas2),
        meslek: asString(data.meslek),
        ilanBasligi: asString(data.ilanBasligi),
        deneyimSeviyesi: asString(data.deneyimSeviyesi),
        basvuruSayisi: asInt(data.basvuruSayisi),
        pozisyonSayisi: asInt(data.pozisyonSayisi) || 1,
        viewCount: asInt(data.viewCount),
        applicationCount: asInt(data.applicationCount),
        endedAt: asInt(data.endedAt),
        about: asString(data.about),
    };
}
function shouldIndex(doc) {
    const hasCoreText = doc.title.trim().length > 0 ||
        (doc.description || "").trim().length > 0 ||
        (doc.detailsText || "").trim().length > 0;
    return doc.active && hasCoreText;
}
async function syncEducationDoc(entity, rawDocId, afterData) {
    if (!afterData) {
        await deleteDoc(entity, rawDocId);
        return;
    }
    const doc = await buildSearchDocForIndexing(entity, rawDocId, afterData);
    if (!shouldIndex(doc)) {
        await deleteDoc(entity, rawDocId);
        return;
    }
    await upsertDoc(entity, doc);
}
function toHitOutput(hitRaw, collection) {
    const hit = (hitRaw || {});
    const doc = (hit.document || {});
    const tags = Array.isArray(doc.tags) ? doc.tags.map((x) => String(x || "")) : [];
    return {
        id: String(doc.id || ""),
        docId: String(doc.docId || ""),
        entity: String(doc.entity || ""),
        collection,
        title: String(doc.title || ""),
        subtitle: String(doc.subtitle || ""),
        description: String(doc.description || ""),
        ownerId: String(doc.ownerId || ""),
        timeStamp: Number(doc.timeStamp || 0),
        city: String(doc.city || ""),
        town: String(doc.town || ""),
        country: String(doc.country || ""),
        cover: String(doc.cover || ""),
        nickname: String(doc.nickname || ""),
        displayName: String(doc.displayName || ""),
        avatarUrl: String(doc.avatarUrl || ""),
        tags,
        rozet: String(doc.rozet || ""),
        shortDescription: String(doc.shortDescription || ""),
        aciklama: String(doc.aciklama || ""),
        img: String(doc.cover || ""),
        img2: String(doc.img2 || ""),
        logo: String(doc.logo || ""),
        baslangicTarihi: String(doc.baslangicTarihi || ""),
        bitisTarihi: String(doc.bitisTarihi || ""),
        basvuruKosullari: String(doc.basvuruKosullari || ""),
        basvuruURL: String(doc.basvuruURL || ""),
        basvuruYapilacakYer: String(doc.basvuruYapilacakYer || ""),
        bursVeren: String(doc.bursVeren || ""),
        egitimKitlesi: String(doc.egitimKitlesi || ""),
        geriOdemeli: String(doc.geriOdemeli || ""),
        hedefKitle: String(doc.hedefKitle || ""),
        mukerrerDurumu: String(doc.mukerrerDurumu || ""),
        ogrenciSayisi: String(doc.ogrenciSayisi || ""),
        tutar: String(doc.tutar || ""),
        website: String(doc.website || ""),
        lisansTuru: String(doc.lisansTuru || ""),
        template: String(doc.template || ""),
        ulke: String(doc.ulke || ""),
        altEgitimKitlesi: Array.isArray(doc.altEgitimKitlesi) ? doc.altEgitimKitlesi.map((x) => String(x || "")) : [],
        aylar: Array.isArray(doc.aylar) ? doc.aylar.map((x) => String(x || "")) : [],
        belgeler: Array.isArray(doc.belgeler) ? doc.belgeler.map((x) => String(x || "")) : [],
        sehirler: Array.isArray(doc.sehirler) ? doc.sehirler.map((x) => String(x || "")) : [],
        ilceler: Array.isArray(doc.ilceler) ? doc.ilceler.map((x) => String(x || "")) : [],
        universiteler: Array.isArray(doc.universiteler) ? doc.universiteler.map((x) => String(x || "")) : [],
        liseOrtaOkulIlceler: Array.isArray(doc.liseOrtaOkulIlceler) ? doc.liseOrtaOkulIlceler.map((x) => String(x || "")) : [],
        liseOrtaOkulSehirler: Array.isArray(doc.liseOrtaOkulSehirler) ? doc.liseOrtaOkulSehirler.map((x) => String(x || "")) : [],
        likeCount: Number(doc.likeCount || 0),
        bookmarkCount: Number(doc.bookmarkCount || 0),
        detailsText: String(doc.detailsText || ""),
        brand: String(doc.brand || ""),
        yanHaklar: Array.isArray(doc.yanHaklar) ? doc.yanHaklar.map((x) => String(x || "")) : [],
        calismaGunleri: Array.isArray(doc.calismaGunleri) ? doc.calismaGunleri.map((x) => String(x || "")) : [],
        calismaSaatiBaslangic: String(doc.calismaSaatiBaslangic || ""),
        calismaSaatiBitis: String(doc.calismaSaatiBitis || ""),
        calismaTuru: Array.isArray(doc.calismaTuru) ? doc.calismaTuru.map((x) => String(x || "")) : [],
        ended: doc.ended === true,
        isTanimi: String(doc.isTanimi || ""),
        lat: Number(doc.lat || 0),
        long: Number(doc.long || 0),
        adres: String(doc.adres || ""),
        maas1: Number(doc.maas1 || 0),
        maas2: Number(doc.maas2 || 0),
        meslek: String(doc.meslek || ""),
        ilanBasligi: String(doc.ilanBasligi || ""),
        deneyimSeviyesi: String(doc.deneyimSeviyesi || ""),
        basvuruSayisi: Number(doc.basvuruSayisi || 0),
        pozisyonSayisi: Number(doc.pozisyonSayisi || 0),
        viewCount: Number(doc.viewCount || 0),
        applicationCount: Number(doc.applicationCount || 0),
        endedAt: Number(doc.endedAt || 0),
        about: String(doc.about || ""),
        dersYeri: Array.isArray(doc.dersYeri) ? doc.dersYeri.map((x) => String(x || "")) : [],
        cinsiyet: String(doc.cinsiyet || ""),
        fiyat: Number(doc.fiyat || 0),
        telefon: doc.telefon === true,
        whatsapp: doc.whatsapp === true,
        averageRating: Number(doc.averageRating || 0),
        reviewCount: Number(doc.reviewCount || 0),
        categoryKey: String(doc.categoryKey || ""),
        anaBaslik: String(doc.anaBaslik || ""),
        baslik2: String(doc.baslik2 || ""),
        baslik3: String(doc.baslik3 || ""),
        dil: String(doc.dil || ""),
        ders: String(doc.ders || ""),
        sinavTuru: String(doc.sinavTuru || ""),
        soruNo: String(doc.soruNo || ""),
        yil: String(doc.yil || ""),
        seq: Number(doc.seq || 0),
        correctCount: Number(doc.correctCount || 0),
        wrongCount: Number(doc.wrongCount || 0),
        soru: String(doc.soru || ""),
        dogruCevap: String(doc.dogruCevap || ""),
        kacCevap: Number(doc.kacCevap || 0),
        diger1: String(doc.diger1 || ""),
        diger2: doc.diger2 === true,
        diger3: Number(doc.diger3 || 0),
        score: Number(hit.text_match || 0),
    };
}
async function searchFromCollection(entity, qRaw, limit, page, filterByRaw = "", sortByRaw = "") {
    const baseUrl = getTypesenseBaseUrl();
    const q = qRaw.trim().length === 0 ? "*" : qRaw.trim();
    const collection = getCollectionName(entity);
    await ensureEntityCollection(entity);
    const queryBy = (() => {
        switch (entity) {
            case "workout":
                return "title,subtitle,description,tags,detailsText,anaBaslik,sinavTuru,ders,soruNo,yil";
            case "past_question":
                return "title,subtitle,description,tags,detailsText,anaBaslik,sinavTuru,baslik2,baslik3,yil,dil";
            case "tutoring":
                return "title,subtitle,description,aciklama,tags,city,town,country,detailsText,nickname,displayName,cinsiyet,dersYeri";
            case "job":
                return "title,subtitle,description,aciklama,tags,city,town,country,detailsText,nickname,displayName,meslek,ilanBasligi,brand";
            default:
                return "title,subtitle,description,aciklama,tags,city,town,country,detailsText,nickname,displayName";
        }
    })();
    const filterBy = filterByRaw.trim();
    const sortBy = sortByRaw.trim();
    const response = await axios_1.default.get(`${baseUrl}/collections/${collection}/documents/search`, {
        headers: headers(),
        timeout: 12000,
        params: {
            q,
            query_by: queryBy,
            per_page: limit,
            page,
            sort_by: sortBy || "timeStamp:desc",
            filter_by: filterBy || "active:=true",
            num_typos: 2,
            exhaustive_search: true,
        },
    });
    const data = response.data || {};
    const rawHits = Array.isArray(data.hits) ? data.hits : [];
    const hits = rawHits.map((item) => toHitOutput(item, collection));
    return {
        hits,
        found: Number(data.found || hits.length),
        outOf: Number(data.out_of || hits.length),
        searchTimeMs: Number(data.search_time_ms || 0),
    };
}
async function searchEducationFromTypesense(qRaw, limit, page, entity, filterBy = "", sortBy = "") {
    const q = qRaw.trim().length === 0 ? "*" : qRaw.trim();
    if (entity) {
        const one = await searchFromCollection(entity, qRaw, limit, page, filterBy, sortBy);
        return {
            q,
            page,
            limit,
            found: one.found,
            out_of: one.outOf,
            search_time_ms: one.searchTimeMs,
            hits: one.hits,
        };
    }
    const perCollectionLimit = Math.max(limit, 20);
    const results = await Promise.all(EDUCATION_ENTITIES.map((e) => searchFromCollection(e, qRaw, perCollectionLimit, page, filterBy, sortBy)));
    const merged = results.flatMap((x) => x.hits);
    merged.sort((a, b) => {
        if (b.score !== a.score)
            return b.score - a.score;
        return b.timeStamp - a.timeStamp;
    });
    return {
        q,
        page,
        limit,
        found: results.reduce((sum, x) => sum + x.found, 0),
        out_of: results.reduce((sum, x) => sum + x.outOf, 0),
        search_time_ms: results.reduce((sum, x) => sum + x.searchTimeMs, 0),
        hits: merged.slice(0, limit),
    };
}
function queryForEntity(entity, limit, cursor) {
    const db = (0, firestore_2.getFirestore)();
    switch (entity) {
        case "scholarship": {
            let q = db
                .collection("catalog")
                .doc("education")
                .collection("scholarships")
                .orderBy(firestore_2.FieldPath.documentId())
                .limit(limit);
            if (cursor)
                q = q.startAfter(cursor);
            return q;
        }
        case "practice_exam": {
            let q = db.collection("practiceExams").orderBy(firestore_2.FieldPath.documentId()).limit(limit);
            if (cursor)
                q = q.startAfter(cursor);
            return q;
        }
        case "answer_key": {
            let q = db.collection("books").orderBy(firestore_2.FieldPath.documentId()).limit(limit);
            if (cursor)
                q = q.startAfter(cursor);
            return q;
        }
        case "tutoring": {
            let q = db.collection("educators").orderBy(firestore_2.FieldPath.documentId()).limit(limit);
            if (cursor)
                q = q.startAfter(cursor);
            return q;
        }
        case "job": {
            let q = db.collection("isBul").orderBy(firestore_2.FieldPath.documentId()).limit(limit);
            if (cursor)
                q = q.startAfter(cursor);
            return q;
        }
        case "workout": {
            let q = db.collection("questionBank").orderBy(firestore_2.FieldPath.documentId()).limit(limit);
            if (cursor)
                q = q.startAfter(cursor);
            return q;
        }
        case "past_question": {
            let q = db.collection("questions").orderBy(firestore_2.FieldPath.documentId()).limit(limit);
            if (cursor)
                q = q.startAfter(cursor);
            return q;
        }
    }
}
exports.f21_syncScholarshipsToTypesense = (0, firestore_1.onDocumentWritten)({
    document: "catalog/education/scholarships/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (event) => {
    ensureAdmin();
    if (!typesenseReady())
        return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data();
    await syncEducationDoc("scholarship", docId, afterData);
});
exports.f21_syncPracticeExamsToTypesense = (0, firestore_1.onDocumentWritten)({
    document: "practiceExams/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (event) => {
    ensureAdmin();
    if (!typesenseReady())
        return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data();
    await syncEducationDoc("practice_exam", docId, afterData);
});
exports.f21_syncAnswerKeysToTypesense = (0, firestore_1.onDocumentWritten)({
    document: "books/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (event) => {
    ensureAdmin();
    if (!typesenseReady())
        return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data();
    await syncEducationDoc("answer_key", docId, afterData);
});
exports.f21_syncTutoringsToTypesense = (0, firestore_1.onDocumentWritten)({
    document: "educators/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (event) => {
    ensureAdmin();
    if (!typesenseReady())
        return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data();
    await syncEducationDoc("tutoring", docId, afterData);
});
exports.f21_syncJobsToTypesense = (0, firestore_1.onDocumentWritten)({
    document: "isBul/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (event) => {
    ensureAdmin();
    if (!typesenseReady())
        return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data();
    await syncEducationDoc("job", docId, afterData);
});
exports.f21_syncWorkoutsToTypesense = (0, firestore_1.onDocumentWritten)({
    document: "questionBank/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (event) => {
    ensureAdmin();
    if (!typesenseReady())
        return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data();
    await syncEducationDoc("workout", docId, afterData);
});
exports.f21_syncPastQuestionsToTypesense = (0, firestore_1.onDocumentWritten)({
    document: "questions/{docId}",
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (event) => {
    ensureAdmin();
    if (!typesenseReady())
        return;
    const docId = String(event.params.docId || "");
    const afterData = event.data?.after?.data();
    await syncEducationDoc("past_question", docId, afterData);
});
exports.f21_ensureEducationTypesenseCollectionCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 120,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    ensureAdmin();
    requireAdminAuth(request);
    if (!typesenseReady()) {
        throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
    }
    const rawEntity = request.data?.entity;
    if (rawEntity !== undefined && !isEducationEntity(rawEntity)) {
        throw new https_1.HttpsError("invalid-argument", "invalid_entity");
    }
    if (rawEntity) {
        await ensureEntityCollection(rawEntity);
        return { ok: true, entity: rawEntity, collection: getCollectionName(rawEntity) };
    }
    await ensureAllEntityCollections();
    return {
        ok: true,
        entities: EDUCATION_ENTITIES.map((entity) => ({
            entity,
            collection: getCollectionName(entity),
        })),
    };
});
exports.f21_searchEducationCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 30,
    memory: "256MiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    const uid = requireAuth(request);
    rateLimiter_1.RateLimits.general(uid);
    if (!typesenseReady()) {
        throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
    }
    const q = String(request.data?.q || "");
    const limit = Math.max(1, Math.min(MAX_LIMIT, Number(request.data?.limit || 20)));
    const page = Math.max(1, Number(request.data?.page || 1));
    const filterBy = String(request.data?.filterBy || "").trim();
    const sortBy = String(request.data?.sortBy || "").trim();
    const entityRaw = request.data?.entity;
    const entity = isEducationEntity(entityRaw) ? entityRaw : undefined;
    try {
        return await searchEducationFromTypesense(q, limit, page, entity, filterBy, sortBy);
    }
    catch (err) {
        const axiosErr = err;
        const detail = axiosErr?.response?.data || err?.message || "unknown_error";
        throw new https_1.HttpsError("internal", "typesense_search_failed", detail);
    }
});
exports.f21_reindexEducationToTypesenseCallable = (0, https_1.onCall)({
    region: REGION,
    timeoutSeconds: 540,
    memory: "1GiB",
    secrets: ["TYPESENSE_HOST", "TYPESENSE_API_KEY"],
}, async (request) => {
    ensureAdmin();
    requireAdminAuth(request);
    try {
        if (!typesenseReady()) {
            throw new https_1.HttpsError("failed-precondition", "typesense_not_configured");
        }
        const entityRaw = request.data?.entity;
        if (!isEducationEntity(entityRaw)) {
            throw new https_1.HttpsError("invalid-argument", "invalid_entity");
        }
        const entity = entityRaw;
        const limit = Math.max(1, Math.min(500, Number(request.data?.limit || 200)));
        const cursor = String(request.data?.cursor || "").trim();
        const dryRun = request.data?.dryRun === true;
        await ensureEntityCollection(entity);
        const snap = await queryForEntity(entity, limit, cursor).get();
        let scanned = 0;
        let upserted = 0;
        let deleted = 0;
        let skipped = 0;
        for (const docSnap of snap.docs) {
            scanned += 1;
            const rawDocId = docSnap.id;
            const data = docSnap.data();
            const doc = await buildSearchDocForIndexing(entity, rawDocId, data);
            if (!shouldIndex(doc)) {
                if (!dryRun) {
                    await deleteDoc(entity, rawDocId);
                }
                deleted += 1;
                continue;
            }
            if (!doc.title.trim() && !(doc.detailsText || "").trim()) {
                skipped += 1;
                continue;
            }
            if (!dryRun) {
                await upsertDoc(entity, doc);
            }
            upserted += 1;
        }
        const last = snap.docs[snap.docs.length - 1];
        const nextCursor = last ? last.id : null;
        const done = snap.docs.length < limit;
        return {
            entity,
            scanned,
            upserted,
            deleted,
            skipped,
            nextCursor,
            done,
        };
    }
    catch (err) {
        const axiosErr = err;
        const detail = axiosErr?.response?.data || err?.message || "unknown_error";
        console.error("f21_reindex_education_failed", {
            detail,
            entity: request.data?.entity || null,
            cursor: request.data?.cursor || null,
        });
        throw new https_1.HttpsError("internal", "typesense_reindex_failed", detail);
    }
});
//# sourceMappingURL=21_typesenseEducation.js.map