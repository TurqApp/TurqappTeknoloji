# Post Asset URL Contract

Date: `2026-04-30`

## Goal

Make public post assets use one canonical CDN contract instead of mixed
`cdn.turqapp.com/Posts/...`, `cdn.turqapp.com/v0/b/...`, and
`firebasestorage.googleapis.com/v0/b/...` shapes.

This contract is for **public post playback and preview assets**. It does not
change short-link prefixes or private upload rules.

## Canonical Public URLs

### Short Links

- post: `https://turqapp.com/p/{shortId}`
- story: `https://turqapp.com/s/{shortId}`
- user: `https://turqapp.com/u/{shortId}`
- market: `https://turqapp.com/m/{shortId}`
- education: `https://turqapp.com/e/{shortId}`
- job: `https://turqapp.com/i/{shortId}`

`docId` is never a public short-link identifier.

### Post Playback Assets

- HLS master: `https://cdn.turqapp.com/Posts/{docId}/hls/master.m3u8`
- HLS variant: `https://cdn.turqapp.com/Posts/{docId}/hls/{variant}/playlist.m3u8`
- HLS segment: `https://cdn.turqapp.com/Posts/{docId}/hls/{variant}/seg_{index}.ts`
- MP4 fallback: `https://cdn.turqapp.com/Posts/{docId}/video.mp4`

### Post Visual Assets

- thumbnail: `https://cdn.turqapp.com/Posts/{docId}/thumbnail.webp`

### Post Images

- image 0: `https://cdn.turqapp.com/Posts/{docId}/image_0.webp`
- image N: `https://cdn.turqapp.com/Posts/{docId}/image_{n}.webp`

The public-read rollout for canonical post image URLs is complete. Functions and
backfill scripts should no longer emit tokenized `v0/b/...` image URLs for post
documents.

### User Avatar Assets

- user avatar: `https://cdn.turqapp.com/users/{uid}/{fileName}`

Canonical user avatars now use the clean `/users/...` CDN path rather than
tokenized Firebase download URLs.

## Non-Canonical Legacy Shapes

These are considered legacy for public post assets and should not be emitted by
functions after cleanup:

- `https://cdn.turqapp.com/v0/b/.../o/Posts%2F...?...token=...`
- `https://firebasestorage.googleapis.com/v0/b/.../o/Posts%2F...?...token=...`
- `https://firebasestorage.googleapis.com/v0/b/.../o/users%2F...?...token=...`
- `https://cdn.turqapp.com/v0/b/.../o/users%2F...?...token=...`

These legacy shapes may continue to exist temporarily during migration, but
functions and backfill scripts must converge fields onto the canonical
`https://cdn.turqapp.com/Posts/...` form.

## Canonical Field Mapping

### Post document fields

- `thumbnail` -> canonical thumbnail URL
- `img[]` -> canonical image URLs
- `video` -> canonical HLS master URL when `hlsStatus == ready`
- `hlsMasterUrl` -> canonical HLS master URL
- `shortUrl` -> canonical short-link URL using `shortId`
- `authorAvatarUrl` -> canonical user avatar URL
- `avatarUrl` -> canonical user avatar URL

`video.mp4` URLs are not a public contract target in this project. Any posts
still pointing at tokenized MP4 URLs belong to a separate failed-HLS repair
queue, not to the canonical URL backfill.

### Short-link meta

- Open Graph preview image must use the canonical asset URL for the post
- Short-link runtime must not construct preview URLs from legacy tokenized post
  assets when a canonical `Posts/...` path exists
- User profile preview images and avatar references must resolve to canonical
  `users/...` CDN paths when the source asset belongs to `users/{uid}/...`

## Ownership

Canonical asset URLs must be produced by:

- `functions/src/hlsTranscode.ts`
- `functions/src/postsMigrationScheduler.ts`
- `functions/src/thumbnails.ts`
- `functions/src/17_shortLinksIndex.ts`
- `functions/src/09_userProfile.ts`

The Flutter app should consume these canonical values rather than inventing its
own public asset URL shapes.
