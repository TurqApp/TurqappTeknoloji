#!/usr/bin/env node
/* eslint-disable no-console */
const admin = require('firebase-admin');
const {buildOptions, asString, asNum} = require('./posts_migration_shared');

const MANIFEST_POST_LIMIT = 80;
const MANIFEST_RESHARE_LIMIT = 30;
const MANIFEST_SCHEMA_VERSION = 1;
const USER_SOURCE_USERS = 'users';
const USER_SOURCE_POSTS = 'posts';

function arg(name, fallback = undefined) {
  const idx = process.argv.indexOf(`--${name}`);
  if (idx === -1) return fallback;
  return process.argv[idx + 1];
}

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

function asBool(value, fallback = false) {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number') return value !== 0;
  if (typeof value === 'string') {
    const normalized = value.trim().toLowerCase();
    if (normalized === 'true' || normalized === '1') return true;
    if (normalized === 'false' || normalized === '0') return false;
  }
  return fallback;
}

function firstNonEmpty(values) {
  for (const value of values) {
    const normalized = asString(value);
    if (normalized) return normalized;
  }
  return '';
}

function chunk(list, size) {
  const result = [];
  for (let index = 0; index < list.length; index += size) {
    result.push(list.slice(index, index + size));
  }
  return result;
}

function cloneMap(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) {
    return {};
  }
  return JSON.parse(JSON.stringify(value));
}

function buildHeader(userData = {}) {
  const profile = cloneMap(userData.profile);
  return {
    nickname: firstNonEmpty([userData.nickname, profile.nickname]),
    displayName: firstNonEmpty([
      userData.displayName,
      userData.fullName,
      `${asString(userData.firstName)} ${asString(userData.lastName)}`.trim(),
      profile.displayName,
      `${asString(profile.firstName)} ${asString(profile.lastName)}`.trim(),
    ]),
    avatarUrl: firstNonEmpty([userData.avatarUrl, profile.avatarUrl]),
    rozet: firstNonEmpty([userData.rozet, profile.rozet]),
    bio: firstNonEmpty([userData.bio, profile.bio]),
    adres: firstNonEmpty([userData.adres, profile.adres]),
    meslekKategori: firstNonEmpty([
      userData.meslekKategori,
      profile.meslekKategori,
    ]),
    followerCount:
      asNum(userData.counterOfFollowers, asNum(userData.followersCount, 0)) || 0,
    followingCount:
      asNum(
        userData.counterOfFollowings,
        asNum(userData.followingCount, 0),
      ) || 0,
  };
}

function encodePostItem({
  docId,
  data,
  uid,
  header,
  refreshAuthorSnapshot = false,
  reshareTimestamp = 0,
}) {
  const cloned = cloneMap(data);
  if (refreshAuthorSnapshot) {
    if (header.nickname) cloned.authorNickname = header.nickname;
    if (header.displayName) cloned.authorDisplayName = header.displayName;
    if (header.avatarUrl) cloned.authorAvatarUrl = header.avatarUrl;
    if (header.rozet) cloned.rozet = header.rozet;
    cloned.userID = uid;
  }
  if (reshareTimestamp > 0) {
    const reshareMap = cloneMap(cloned.reshareMap);
    reshareMap.manifestReshareTimeStamp = reshareTimestamp;
    cloned.reshareMap = reshareMap;
  }
  return {
    docID: docId,
    data: cloned,
  };
}

function isVisiblePost(data, nowMs) {
  if (!data || typeof data !== 'object') return false;
  if (asBool(data.deletedPost, false)) return false;
  if (asBool(data.gizlendi, false)) return false;
  if (asBool(data.arsiv, false)) return false;
  if (asBool(data.isUploading, false)) return false;
  const timeStamp = asNum(data.timeStamp, 0);
  if (timeStamp <= 0 || timeStamp > nowMs) return false;
  return true;
}

async function fetchVisiblePosts(db, uid, nowMs) {
  const snap = await db
    .collection('Posts')
    .where('userID', '==', uid)
    .where('arsiv', '==', false)
    .where('flood', '==', false)
    .where('timeStamp', '<=', nowMs)
    .orderBy('timeStamp', 'desc')
    .limit(MANIFEST_POST_LIMIT)
    .get();

  return snap.docs
    .map((doc) => ({
      docId: doc.id,
      data: cloneMap(doc.data()),
    }))
    .filter((entry) => isVisiblePost(entry.data, nowMs));
}

async function fetchVisibleReshares(db, uid, nowMs) {
  const refSnap = await db
    .collection('users')
    .doc(uid)
    .collection('reshared_posts')
    .where('timeStamp', '<=', nowMs)
    .orderBy('timeStamp', 'desc')
    .limit(MANIFEST_RESHARE_LIMIT)
    .get();

  const refs = refSnap.docs
    .map((doc) => {
      const data = doc.data() || {};
      const postId = asString(data.post_docID || doc.id);
      return {
        postId,
        timeStamp: asNum(data.timeStamp, 0),
      };
    })
    .filter((entry) => entry.postId);

  if (refs.length === 0) {
    return [];
  }

  const dedupedRefs = [];
  const seen = new Set();
  for (const entry of refs) {
    if (seen.has(entry.postId)) continue;
    seen.add(entry.postId);
    dedupedRefs.push(entry);
  }

  const byId = new Map();
  for (const ids of chunk(dedupedRefs.map((entry) => entry.postId), 10)) {
    const postSnap = await db
      .collection('Posts')
      .where(admin.firestore.FieldPath.documentId(), 'in', ids)
      .get();
    for (const doc of postSnap.docs) {
      byId.set(doc.id, cloneMap(doc.data()));
    }
  }

  return dedupedRefs
    .map((entry) => ({
      docId: entry.postId,
      timeStamp: entry.timeStamp,
      data: byId.get(entry.postId) || null,
    }))
    .filter((entry) => entry.data && isVisiblePost(entry.data, nowMs));
}

function buildManifestPayload({uid, generatedAt, header, posts, reshares}) {
  const all = posts.map((entry) => entry.item);
  const photos = posts
    .filter((entry) => !asString(entry.item.data.video) && !asString(entry.item.data.hlsMasterUrl))
    .map((entry) => entry.item);
  const videos = posts
    .filter(
      (entry) =>
        asString(entry.item.data.video) || asString(entry.item.data.hlsMasterUrl),
    )
    .map((entry) => entry.item);

  return {
    schemaVersion: MANIFEST_SCHEMA_VERSION,
    userId: uid,
    manifestId: `profile_${uid}_v${generatedAt}`,
    generatedAt,
    header,
    all: {items: all},
    photos: {items: photos},
    videos: {items: videos},
    reshares: {items: reshares.map((entry) => entry.item)},
    scheduled: {items: []},
  };
}

async function processUser({
  db,
  bucket,
  uid,
  generatedAt,
  nowMs,
  apply,
}) {
  const userSnap = await db.collection('users').doc(uid).get();
  if (!userSnap.exists) {
    return {uid, skipped: 'user_not_found'};
  }
  const userData = cloneMap(userSnap.data());
  const header = buildHeader(userData);
  const visiblePosts = await fetchVisiblePosts(db, uid, nowMs);
  const visibleReshares = await fetchVisibleReshares(db, uid, nowMs);

  const encodedPosts = visiblePosts.map((entry) => ({
    ...entry,
    item: encodePostItem({
      docId: entry.docId,
      data: entry.data,
      uid,
      header,
      refreshAuthorSnapshot: true,
    }),
  }));
  const encodedReshares = visibleReshares.map((entry) => ({
    ...entry,
    item: encodePostItem({
      docId: entry.docId,
      data: entry.data,
      uid,
      header,
      refreshAuthorSnapshot: false,
      reshareTimestamp: entry.timeStamp,
    }),
  }));

  const payload = buildManifestPayload({
    uid,
    generatedAt,
    header,
    posts: encodedPosts,
    reshares: encodedReshares,
  });
  const storagePath = `users/${uid}/profile_manifest/manifest_v${generatedAt}.json`;

  if (!apply) {
    return {
      uid,
      dryRun: true,
      storagePath,
      bucketCounts: {
        all: payload.all.items.length,
        photos: payload.photos.items.length,
        videos: payload.videos.items.length,
        reshares: payload.reshares.items.length,
      },
    };
  }

  await bucket.file(storagePath).save(
    JSON.stringify(payload),
    {
      metadata: {
        contentType: 'application/json; charset=utf-8',
        cacheControl: 'private, max-age=300',
      },
    },
  );

  await db.collection('users').doc(uid).set(
    {
      profileManifest: {
        schemaVersion: MANIFEST_SCHEMA_VERSION,
        manifestId: payload.manifestId,
        activeVersion: `v${generatedAt}`,
        storagePath,
        itemCount: payload.all.items.length,
        bucketCounts: {
          all: payload.all.items.length,
          photos: payload.photos.items.length,
          videos: payload.videos.items.length,
          reshares: payload.reshares.items.length,
        },
        updatedAt: generatedAt,
        lastRebuildAt: generatedAt,
        lastEventAt: generatedAt,
        dirty: false,
        rebuildReason: 'backfill_visible_now',
        ttlUntil: generatedAt + (7 * 24 * 60 * 60 * 1000),
        visibility: 'public_safe_client',
      },
    },
    {merge: true},
  );

  return {
    uid,
    dryRun: false,
    storagePath,
    bucketCounts: {
      all: payload.all.items.length,
      photos: payload.photos.items.length,
      videos: payload.videos.items.length,
      reshares: payload.reshares.items.length,
    },
  };
}

async function listTargetUserIdsFromPosts(db, limitUsers, nowMs) {
  const targetLimit = limitUsers > 0 ? limitUsers : Number.POSITIVE_INFINITY;
  const seen = new Set();
  let lastDoc = null;

  while (seen.size < targetLimit) {
    let query = db
      .collection('Posts')
      .where('arsiv', '==', false)
      .where('flood', '==', false)
      .where('timeStamp', '<=', nowMs)
      .orderBy('timeStamp', 'desc')
      .limit(200);
    if (lastDoc) {
      query = query.startAfter(lastDoc);
    }
    const snap = await query.get();
    if (snap.empty) break;
    for (const doc of snap.docs) {
      const data = doc.data() || {};
      if (!isVisiblePost(data, nowMs)) continue;
      const uid = asString(data.userID);
      if (!uid) continue;
      seen.add(uid);
      if (seen.size >= targetLimit) break;
    }
    lastDoc = snap.docs[snap.docs.length - 1] || null;
    if (snap.size < 200) break;
  }

  return Array.from(seen);
}

async function listTargetUserIds(db, explicitUid, limitUsers, nowMs, userSource) {
  if (explicitUid) return [explicitUid];
  if (userSource === USER_SOURCE_POSTS) {
    return listTargetUserIdsFromPosts(db, limitUsers, nowMs);
  }
  let query = db.collection('users').orderBy(admin.firestore.FieldPath.documentId());
  if (limitUsers > 0) {
    query = query.limit(limitUsers);
  }
  const snap = await query.get();
  return snap.docs.map((doc) => doc.id).filter(Boolean);
}

async function main() {
  const options = buildOptions();
  const targetKey = options.targetKey;
  const targetBucket = options.targetBucket;
  const uid = asString(arg('uid'));
  const limitUsers = Number(arg('limit-users', '0')) || 0;
  const apply = hasFlag('apply');
  const nowMs = Number(arg('now-ms', `${Date.now()}`)) || Date.now();
  const generatedAt = Number(arg('generated-at', `${Date.now()}`)) || Date.now();
  const userSource = asString(arg('user-source', USER_SOURCE_POSTS)) || USER_SOURCE_POSTS;

  const credential = admin.credential.cert(require(targetKey));
  const app = admin.initializeApp(
    {
      credential,
      storageBucket: targetBucket,
    },
    `profile-manifest-backfill-${Date.now()}`,
  );

  try {
    const db = app.firestore();
    const bucket = app.storage().bucket();
    const targetUserIds = await listTargetUserIds(
      db,
      uid,
      limitUsers,
      nowMs,
      userSource,
    );
    const results = [];
    for (const targetUid of targetUserIds) {
      const result = await processUser({
        db,
        bucket,
        uid: targetUid,
        generatedAt,
        nowMs,
        apply,
      });
      results.push(result);
      console.log(
        JSON.stringify(
          {
            uid: result.uid,
            dryRun: result.dryRun,
            skipped: result.skipped || null,
            bucketCounts: result.bucketCounts || null,
          },
          null,
          2,
        ),
      );
    }

    console.log(
      JSON.stringify(
        {
          apply,
          nowMs,
          generatedAt,
          userSource,
          userCount: results.length,
        },
        null,
        2,
      ),
    );
  } finally {
    await app.delete();
  }
}

main().catch((error) => {
  console.error('profile_manifest_backfill_failed', error);
  process.exit(1);
});
