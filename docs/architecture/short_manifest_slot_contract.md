# Short Manifest Slot Contract

Short runtime no longer selects candidates with a live motor. The device reads
published short manifest slots in order and does not reorder items for author
diversity.

## Firestore

```text
shortManifest/active
shortManifest/{yyyy-MM-dd}
```

`shortManifest/active` points to the currently published day:

```json
{
  "schemaVersion": 1,
  "date": "2026-04-21",
  "manifestId": "short_2026-04-21_v1",
  "status": "active",
  "indexPath": "shortManifest/2026-04-21/index.json",
  "slotCount": 6,
  "itemsPerSlot": 240,
  "publishedAt": 1776720000000,
  "generatedAt": 1776719900000
}
```

Day documents mirror the active payload for history/debug and include the same
client-readable fields. Clients may read these documents but never write them.

## Storage

```text
shortManifest/{yyyy-MM-dd}/index.json
shortManifest/{yyyy-MM-dd}/slots/slot_001.json
shortManifest/{yyyy-MM-dd}/slots/slot_002.json
```

The device downloads only the active slot and the next slot. It may download the
next day index when the queue crosses a day boundary.

## Index Payload

```json
{
  "schemaVersion": 1,
  "date": "2026-04-21",
  "manifestId": "short_2026-04-21_v1",
  "itemsPerSlot": 240,
  "slotCount": 6,
  "itemCount": 1440,
  "slots": [
    {
      "slotId": "slot_001",
      "slotIndex": 0,
      "itemCount": 240,
      "path": "shortManifest/2026-04-21/slots/slot_001.json"
    }
  ]
}
```

## Slot Payload

Each published slot has exactly 240 items. Slots are sequence packages, not time
windows. A slot is not published until it has 240 valid items.

```json
{
  "schemaVersion": 1,
  "date": "2026-04-21",
  "manifestId": "short_2026-04-21_v1",
  "slotId": "slot_001",
  "slotIndex": 0,
  "itemCount": 240,
  "items": []
}
```

Every item must be self-contained for first render:

```json
{
  "docId": "postId",
  "userID": "authorUid",
  "authorNickname": "nickname",
  "authorDisplayName": "Display Name",
  "authorAvatarUrl": "https://cdn.turqapp.com/avatar.webp",
  "rozet": "Mavi",
  "metin": "caption",
  "thumbnail": "https://cdn.turqapp.com/thumb.jpg",
  "posterCandidates": ["https://cdn.turqapp.com/thumb.jpg"],
  "video": "",
  "hlsMasterUrl": "https://cdn.turqapp.com/Posts/postId/hls/master.m3u8",
  "hlsStatus": "ready",
  "hasPlayableVideo": true,
  "aspectRatio": 0.5625,
  "timeStamp": 1776710000000,
  "createdAtTs": 1776710000000,
  "shortId": "ZFBUjTe",
  "shortUrl": "https://turqapp.com/p/ZFBUjTe",
  "stats": {
    "likeCount": 0,
    "commentCount": 0,
    "savedCount": 0,
    "retryCount": 0,
    "statsCount": 0
  },
  "flags": {
    "deletedPost": false,
    "gizlendi": false,
    "arsiv": false,
    "flood": false,
    "floodCount": 1,
    "paylasGizliligi": 0
  }
}
```

Comments are not included in the manifest. Only `commentCount` is included.

## Device Rules

- Keep exactly two slots in the local work queue: current and next.
- Warm avatars/posters for both slots.
- On Wi-Fi, warm first three HLS segments for current and next slots with a
  controlled queue.
- When the current slot is consumed, promote next to current and download the
  following slot.
- Do not skip or reorder items for author diversity.
- Do not count inserted ad pages as slot items.

## Backend Validator Rules

- Slot item count is exactly 240.
- `docId` is unique across the published manifest day.
- Required first-render metadata is present.
- `shortUrl` is present.
- `hasPlayableVideo` is true and `hlsStatus` is `ready`.
- Hidden, deleted, archived, and flood series posts are excluded.
- Author diversity is enforced before publishing; the device never fixes it.
