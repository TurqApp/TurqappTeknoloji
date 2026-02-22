# Users Collection Blueprint

**Goal**: deliver Instagram/Twitter-class responsiveness while modelling rich student-centric profiles for the next-generation Turq social platform.

## Design Pillars
- Latency budget: <60 ms reads on hot paths (feed, profile, messaging).
- Document size target: ≤5 KB hot document, ≤1 KB shards, ≤3 KB cold pieces.
- Write amplification is acceptable when it reduces read cost; eventual consistency window ≤5 s.
- Sensitive attributes isolated into private subcollections to simplify rules & caching.
- Schema versioned; client contract enforced by generated Dart models.

## High-Level Layout

| Scope           | Path                                      | Purpose                              | Notes |
|-----------------|-------------------------------------------|--------------------------------------|-------|
| Hot profile     | `users/{uid}`                             | Feed/avatar/identity + counters      | Cached aggressively, read in every session |
| Cold-private    | `users/{uid}/private/profile`             | PII & compliance sensitive fields    | Optional encryption-at-rest via Cloud Functions |
| Education graph | `users/{uid}/education/{entryId}`         | Student achievements & goals         | Lazy loaded when visiting education tab |
| Connections     | `users/{uid}/relationships/{doc}`         | Block/mute/follow requests metadata  | Enables per-user security rules |
| Stats shards    | `users/{uid}/stats/{shardId}`             | Denormalised counters (10 shards)    | Batched Cloud Functions updates |
| Activity log    | `users/{uid}/auditTrail/{entryId}`        | Sign-in, device, moderation events   | 30-day retention |
| Usernames map   | `usernames/{handle}`                      | Handle uniqueness and lookup         | Value: `{ uid }` |

> **Why this split?** Hot data must stay slim for list rendering, while privacy, education background and compliance data remain accessible without bloating every read.

## `users/{uid}` Document (Hot)

```json
{
  "uid": "user_9r7h3",
  "handle": "ahmety",
  "displayName": "Ahmet Yılmaz",
  "avatar": {
    "full": "gs://turqapp/users/ahmety/avatar_full.jpg",
    "thumb": "gs://turqapp/users/ahmety/avatar_thumb.jpg",
    "blurHash": "LFE.@D9F01_2%LRjxuxu00"
  },
  "headline": "YKS 2025 • Bilgisayar Mühendisi adayı",
  "bio": "STEM tutkunu, mentor arıyorum.",
  "badges": ["verified_candidate", "mentor_ready"],
  "account": {
    "role": "student",            // student, mentor, ambassador, admin
    "tier": "plus",               // free, plus, elite
    "verified": true,
    "verifiedAt": "2025-01-12T09:45:32Z"
  },
  "engagement": {
    "followers": 1820,
    "following": 322,
    "posts": 94,
    "reactions": 12840,
    "lastActiveAt": "2025-02-03T12:21:45Z"
  },
  "preferences": {
    "language": "tr",
    "timezone": "Europe/Istanbul",
    "darkMode": true,
    "dmPolicy": "followers",      // everyone, followers, none
    "mentionPolicy": "everyone"
  },
  "discoverability": {
    "searchable": true,
    "geoHash": "sxk3k",
    "primaryTags": ["yks", "bilgisayar", "sayisal"]
  },
  "safety": {
    "status": "active",           // active, suspended, banned, shadow
    "strikeCount": 0,
    "riskLevel": "low"
  },
  "metadata": {
    "schemaVersion": 3,
    "createdAt": "2024-06-18T08:01:12Z",
    "updatedAt": "2025-02-03T12:21:45Z"
  }
}
```

## Private Profile (`users/{uid}/private/profile`)
- Stores KVKK/GDPR regulated information and contact redundancy.
- Protected by Firestore rules ensuring only owner & service accounts can read.
- Recommended fields:
  - `contact`: alternative email, guardian phones, emergency contact.
  - `identity`: birthdate, nationalIdHash (AES256 + HMAC).
  - `address`: encrypted structured address fields, `geoHash` resolution reduced.
  - `financial`: optional IBAN tokens for scholarship payouts.
  - `consents`: marketing, research, parental approvals.

## Education Records (`users/{uid}/education/{entryId}`)
- Each entry describes a schooling period, exam score, course, or certification.
- Suggested document structure:

```json
{
  "type": "exam",                  // school, course, exam, award
  "title": "TYT 2024",
  "institution": "ÖSYM",
  "startDate": "2024-06-15",
  "endDate": "2024-06-16",
  "score": {
    "raw": 481.75,
    "percentile": 0.94
  },
  "tags": ["sayisal"],
  "visibility": "followers",
  "createdAt": "2024-06-20T09:14:00Z",
  "updatedAt": "2024-06-20T09:14:00Z"
}
```

## Relationship Slice (`users/{uid}/relationships`)
- Docs keyed by `{otherUid}` for fast lookup.
- Fields: `type` (`blocked`, `muted`, `closeFriend`), `since`, `reason`, `moderationNotes`.
- Index composite on `(type, since desc)` to render filtered lists.

## Engagement Counters
- Distributed counter pattern using 10 shards under `users/{uid}/stats/shard_{0-9}`.
- Each shard stores `{ followers: int, following: int, reactions: int }`.
- Batched Cloud Function updates triggered on follow/like actions.
- Aggregated total cached under `users/{uid}.engagement` for instant reads.

## Indexing & Query Tips
- Unique handle enforcement via `usernames/{handle}` map + security rule ensuring one mapping per UID.
- Composite indexes:
  - `users` on `(discoverability.primaryTags array, engagement.followers desc)`.
  - `users` on `(account.role, safety.status, metadata.updatedAt desc)` for moderation dashboards.
- TTL indexes for `auditTrail` via automated export to BigQuery (Firestore native TTL when available).

## Security & Compliance Notes
- Apply Firebase Auth custom claims for `role` and `tier`; keep Firestore document authoritative.
- Use Cloud Functions to redact/remove PII when `account.status` transitions to `banned` or user triggers erase.
- Log schema version in Cloud Logging during writes to monitor outdated client payloads.

## Client Integration Checklist
- Generate immutable Dart models (e.g., Freezed) with converters for nested maps.
- Separate DTOs for write operations to avoid accidentally sending read-only fields.
- Use Firestore cache (`GetDocument`, `listen`) with stale-while-revalidate strategy; combine with local Hive/Isar for offline.
- Emit domain events (e.g., `UserProfileUpdated`) through a presentation layer (BLoC/StateNotifier) to keep UI reactive.

