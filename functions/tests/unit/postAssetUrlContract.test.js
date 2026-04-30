const test = require("node:test");
const assert = require("node:assert/strict");

const {
  buildCanonicalPostAssetUrlFromStoragePath,
  buildCanonicalPostHlsUrl,
  canonicalizeKnownPublicPostAssetUrl,
  canonicalizeKnownPublicUserAssetUrl,
  decodeStorageObjectPathFromUrl,
} = require("../../lib/postAssetUrlContract.js");

test("buildCanonicalPostHlsUrl keeps canonical CDN shape stable", () => {
  assert.equal(
    buildCanonicalPostHlsUrl("abc123"),
    "https://cdn.turqapp.com/Posts/abc123/hls/master.m3u8",
  );
});

test("canonical helper rewrites tokenized post thumbnail URLs to /Posts path", () => {
  const raw =
    "https://cdn.turqapp.com/v0/b/turqappteknoloji.firebasestorage.app/o/" +
    "Posts%2Fabc123%2Fthumbnail.webp?alt=media&token=token-1";

  assert.equal(
    canonicalizeKnownPublicPostAssetUrl(raw, "abc123"),
    "https://cdn.turqapp.com/Posts/abc123/thumbnail.webp",
  );
});

test("canonical helper rewrites tokenized post image URLs to /Posts path", () => {
  const raw =
    "https://cdn.turqapp.com/v0/b/turqappteknoloji.firebasestorage.app/o/" +
    "Posts%2Fabc123%2Fimage_0.webp?alt=media&token=token-1";

  assert.equal(
    canonicalizeKnownPublicPostAssetUrl(raw, "abc123"),
    "https://cdn.turqapp.com/Posts/abc123/image_0.webp",
  );
});

test("canonical helper rewrites tokenized user avatar URLs to /users path", () => {
  const raw =
    "https://firebasestorage.googleapis.com/v0/b/turqappteknoloji.firebasestorage.app/o/" +
    "users%2Fabc123%2Fabc123_avatarUrl_thumb_150.webp?alt=media&token=token-1";

  assert.equal(
    canonicalizeKnownPublicUserAssetUrl(raw, "abc123"),
    "https://cdn.turqapp.com/users/abc123/abc123_avatarUrl_thumb_150.webp",
  );
});

test("storage object decoder understands canonical /Posts paths", () => {
  const raw = "https://cdn.turqapp.com/Posts/abc123/hls/master.m3u8";
  assert.equal(
    decodeStorageObjectPathFromUrl(raw),
    "Posts/abc123/hls/master.m3u8",
  );
  assert.equal(
    buildCanonicalPostAssetUrlFromStoragePath("Posts/abc123/thumbnail.webp"),
    "https://cdn.turqapp.com/Posts/abc123/thumbnail.webp",
  );
});
