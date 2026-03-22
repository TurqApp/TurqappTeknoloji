const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

const DEFAULT_KEY_PATH =
  "/Users/turqapp/Downloads/turqappteknoloji-firebase-adminsdk-fbsvc-51cf82d72b.json";
const BATCH_SIZE = Number(process.env.BATCH_SIZE || 200);

const EDUCATION_KEYS = [
  "bolum",
  "defAnaBaslik",
  "defDers",
  "defSinavTuru",
  "educationLevel",
  "fakulte",
  "lise",
  "ogrenciNo",
  "ogretimTipi",
  "okul",
  "okulIlce",
  "okulSehir",
  "ortaOkul",
  "ortalamaPuan",
  "ortalamaPuan1",
  "ortalamaPuan2",
  "osymPuanTuru",
  "osysPuan",
  "osysPuani1",
  "osysPuani2",
  "sinif",
  "universite",
  "yuzlukSistem",
];

const FAMILY_KEYS = [
  "bursVerebilir",
  "engelliRaporu",
  "evMulkiyeti",
  "familyInfo",
  "fatherJob",
  "fatherLiving",
  "fatherName",
  "fatherPhone",
  "fatherSalary",
  "fatherSurname",
  "isDisabled",
  "motherJob",
  "motherLiving",
  "motherName",
  "motherPhone",
  "motherSalary",
  "motherSurname",
  "mulkiyet",
  "totalLiving",
  "yurt",
];

const COUNTER_ALIAS_TO_CANONICAL = {
  followerCount: "counterOfFollowers",
  takipciSayisi: "counterOfFollowers",
  followingCount: "counterOfFollowings",
  takipEdilenSayisi: "counterOfFollowings",
  postCount: "counterOfPosts",
  gonderSayisi: "counterOfPosts",
};

const MAPS_TO_REMOVE = [
  "account",
  "profile",
  "preferences",
  "stats",
  "finance",
  "device",
];

const DOTTED_PREFIXES = [
  "education.",
  "family.",
  "account.",
  "profile.",
  "preferences.",
  "stats.",
  "finance.",
  "device.",
];

function readMaybeBrokenJson(keyPath) {
  const raw = fs.readFileSync(keyPath, "utf8");
  const idx = raw.indexOf("{");
  return JSON.parse(idx > 0 ? raw.slice(idx) : raw);
}

function parseArgs(argv) {
  const out = {
    apply: false,
    keyPath: DEFAULT_KEY_PATH,
    uid: null,
    limit: 0,
  };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--apply") out.apply = true;
    if (a === "--key-path" && argv[i + 1]) out.keyPath = argv[++i];
    if (a === "--uid" && argv[i + 1]) out.uid = argv[++i];
    if (a === "--limit" && argv[i + 1]) out.limit = Number(argv[++i]) || 0;
  }
  return out;
}

function asMap(value) {
  if (!value || typeof value !== "object" || Array.isArray(value)) return {};
  return value;
}

function hasOwn(obj, key) {
  return Object.prototype.hasOwnProperty.call(obj, key);
}

function buildUserUpdate(data) {
  const update = {};
  let touched = false;

  const account = asMap(data.account);
  const stats = asMap(data.stats);
  const education = asMap(data.education);
  const family = asMap(data.family);
  const usernameLower = String(
    data.usernameLower || data.username || data.nickname || ""
  )
    .trim()
    .toLowerCase()
    .replace(/\s+/g, "")
    .replace(/[^a-z0-9._]/g, "");

  // fcmToken: root canonical
  if (!hasOwn(data, "fcmToken") && typeof account.fcmToken === "string") {
    update.fcmToken = account.fcmToken;
    touched = true;
  }

  // account root canonical fallback before deleting account map
  const accountPromotions = [
    "accountStatus",
    "emailVerified",
    "ban",
    "bot",
    "deletedAccount",
    "refCode",
  ];
  for (const key of accountPromotions) {
    if (!hasOwn(data, key) && hasOwn(account, key)) {
      update[key] = account[key];
      touched = true;
    }
  }

  // Legacy/new flag mirrors
  const boolMirrors = [
    ["gizliHesap", "isPrivate"],
    ["hesapOnayi", "isApproved"],
    ["deletedAccount", "isDeleted"],
    ["ban", "isBanned"],
    ["bot", "isBot"],
  ];
  for (const [legacy, modern] of boolMirrors) {
    if (hasOwn(data, legacy) && !hasOwn(data, modern)) {
      update[modern] = Boolean(data[legacy]);
      touched = true;
    } else if (hasOwn(data, modern) && !hasOwn(data, legacy)) {
      update[legacy] = Boolean(data[modern]);
      touched = true;
    }
  }

  // Base schema defaults
  if (!hasOwn(data, "version")) {
    update.version = 3;
    touched = true;
  }
  if (!hasOwn(data, "locale")) {
    update.locale = "tr_TR";
    touched = true;
  }
  if (!hasOwn(data, "timezone")) {
    update.timezone = "Europe/Istanbul";
    touched = true;
  }
  if (!hasOwn(data, "isOnboarded")) {
    update.isOnboarded = false;
    touched = true;
  }
  if (!hasOwn(data, "deletedAt")) {
    update.deletedAt = null;
    touched = true;
  }
  if (usernameLower && !hasOwn(data, "usernameLower")) {
    update.usernameLower = usernameLower;
    touched = true;
  }
  if (!hasOwn(data, "createdAt")) {
    update.createdAt = admin.firestore.FieldValue.serverTimestamp();
    touched = true;
  }
  if (!hasOwn(data, "updatedAt")) {
    update.updatedAt = admin.firestore.FieldValue.serverTimestamp();
    touched = true;
  }
  if (!hasOwn(data, "lastActiveAt")) {
    update.lastActiveAt = admin.firestore.FieldValue.serverTimestamp();
    touched = true;
  }
  if (!hasOwn(data, "ad") || typeof data.ad !== "object" || Array.isArray(data.ad)) {
    update.ad = {
      isAdvertiser: false,
      accountStatus: "inactive",
      campaignCount: 0,
      spendTotal: 0,
      lastCampaignAt: null,
      lastImpressionAt: null,
      lastClickAt: null,
    };
    touched = true;
  }

  // Counter canonicalization
  for (const [alias, canonical] of Object.entries(COUNTER_ALIAS_TO_CANONICAL)) {
    if (!hasOwn(data, canonical)) {
      if (hasOwn(data, alias)) {
        update[canonical] = data[alias];
        touched = true;
      } else if (hasOwn(stats, alias)) {
        update[canonical] = stats[alias];
        touched = true;
      }
    }
    if (hasOwn(data, alias)) {
      update[alias] = admin.firestore.FieldValue.delete();
      touched = true;
    }
  }

  // Keep education/family as maps; move root keys into maps then delete root.
  for (const key of EDUCATION_KEYS) {
    if (hasOwn(data, key) && !hasOwn(education, key)) {
      update[`education.${key}`] = data[key];
      touched = true;
    }
    if (hasOwn(data, key)) {
      update[key] = admin.firestore.FieldValue.delete();
      touched = true;
    }
  }

  for (const key of FAMILY_KEYS) {
    if (hasOwn(data, key) && !hasOwn(family, key)) {
      update[`family.${key}`] = data[key];
      touched = true;
    }
    if (hasOwn(data, key)) {
      update[key] = admin.firestore.FieldValue.delete();
      touched = true;
    }
  }

  // Remove stale nested maps that duplicate root structure.
  for (const mapKey of MAPS_TO_REMOVE) {
    if (hasOwn(data, mapKey)) {
      update[mapKey] = admin.firestore.FieldValue.delete();
      touched = true;
    }
  }

  // Remove dotted root keys left from previous migrations.
  for (const key of Object.keys(data)) {
    if (!key.includes(".")) continue;
    if (DOTTED_PREFIXES.some((prefix) => key.startsWith(prefix))) {
      update[key] = admin.firestore.FieldValue.delete();
      touched = true;
    }
  }

  if (touched) {
    update.normalizedUserSchemaAt = admin.firestore.FieldValue.serverTimestamp();
  }

  return { touched, update };
}

async function main() {
  const args = parseArgs(process.argv);
  if (!fs.existsSync(args.keyPath)) {
    throw new Error(`Service account key not found: ${args.keyPath}`);
  }

  const cred = readMaybeBrokenJson(args.keyPath);
  admin.initializeApp({
    credential: admin.credential.cert(cred),
  });
  const db = admin.firestore();

  let query = db
    .collection("users")
    .orderBy(admin.firestore.FieldPath.documentId())
    .limit(BATCH_SIZE);

  const summary = {
    scanned: 0,
    willUpdate: 0,
    updated: 0,
    skipped: 0,
    errors: 0,
  };

  if (args.uid) {
    const single = await db.collection("users").doc(args.uid).get();
    if (!single.exists) {
      console.log("User not found:", args.uid);
      return;
    }
    const data = single.data() || {};
    const { touched, update } = buildUserUpdate(data);
    summary.scanned = 1;
    if (!touched) {
      summary.skipped = 1;
      console.log("No changes needed for", args.uid);
      return;
    }
    summary.willUpdate = 1;
    if (args.apply) {
      await single.ref.update(update);
      summary.updated = 1;
    }
    console.log("Single-user summary:", summary);
    return;
  }

  let lastDoc = null;
  while (true) {
    let runQuery = query;
    if (lastDoc) runQuery = runQuery.startAfter(lastDoc);
    const snap = await runQuery.get();
    if (snap.empty) break;

    const batch = db.batch();
    let batchOps = 0;

    for (const doc of snap.docs) {
      if (args.limit > 0 && summary.scanned >= args.limit) break;
      summary.scanned += 1;
      try {
        const { touched, update } = buildUserUpdate(doc.data() || {});
        if (!touched) {
          summary.skipped += 1;
          continue;
        }
        summary.willUpdate += 1;
        if (args.apply) {
          batch.update(doc.ref, update);
          batchOps += 1;
          if (batchOps >= 450) {
            await batch.commit();
            summary.updated += batchOps;
            batchOps = 0;
          }
        }
      } catch (e) {
        summary.errors += 1;
        console.error("Failed to build update for", doc.id, e);
      }
    }

    if (args.apply && batchOps > 0) {
      await batch.commit();
      summary.updated += batchOps;
    }

    lastDoc = snap.docs[snap.docs.length - 1];
    console.log("progress", summary);
    if (args.limit > 0 && summary.scanned >= args.limit) break;
  }

  console.log(args.apply ? "APPLY summary:" : "DRY RUN summary:", summary);
}

main().catch((e) => {
  console.error("fatal", e);
  process.exit(1);
});
