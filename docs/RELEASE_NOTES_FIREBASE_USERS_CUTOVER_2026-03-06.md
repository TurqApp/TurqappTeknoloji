# Release Notes — Firebase Cost/Perf + Users/Scholarship Cutover

Date: 2026-03-06
Branch: `codex/final-perf-firebase-baseline`
Base checkpoint: `3abcc34` (`chore: pre-user-schema-cutover checkpoint`)
Head: `8189675`

## Scope
- Scholarship (`burs`) collection path migration from root to catalog domain.
- Users schema alignment to canonical fields across app + functions.
- High-traffic module updates for canonical user read paths.
- Safe migration script addition and execution for live data.

## Phase Summary

### Phase 1 — Scholarship path cutover
- Commit: `79044bb` `refactor: move scholarships under catalog/education path`
- Main change:
  - old: `scholarships/{id}`
  - new: `catalog/education/scholarships/{id}`
- Updated areas:
  - App scholarship module read/write paths
  - Functions shortlink resolution
  - Firestore rules for scholarship + nested applications
- Result:
  - scholarship reads/writes resolve from `catalog/education/scholarships`

### Phase 2 — Scholarship data migration tooling
- Commit: `ab9b179` `chore: add scholarships root-to-catalog migration script`
- Added script:
  - `functions/scripts/migrate_scholarships_root_to_catalog_education.js`
- Operational execution (done):
  - dry-run: source `898`, errors `0`
  - apply: copied root docs `898`, nested subcollection docs `14`, errors `0`
  - id parity check: `missingInDst=0`, `extraInDst=0`
- Safety:
  - root `scholarships` left intact (not deleted)

### Phase 3 — Core users canonical alignment (app + functions)
- Commit: `e790a0f` `refactor: prioritize canonical users fields in app and functions`
- Canonical-first fields:
  - `displayName`, `avatarUrl`, `followerCount`, `followingCount`, `postCount`
- Fallback preserved:
  - `nickname`, `avatarUrl`, `takipciSayisi`, `counterOfFollowers`, etc.
- Updated:
  - `CurrentUserModel`, `CurrentUserService`
  - `authorDenorm`, `hybridFeed`, `tutoringNotifications`

### Phase 4 — High-traffic app modules canonical reads
- Commit: `d5818c9` `refactor: normalize users profile reads in high-traffic modules`
- Updated:
  - user profile cache sanitize logic
  - social comments, post sharers, job details, scholarships controllers

### Phase 5 — Story/Explore/SocialProfile lookup standardization
- Commit: `ae3f6b1` `refactor: standardize user lookups in story and explore flows`
- Mention/user resolution order:
  1. `usernames/{handle}` map
  2. `users.username`
  3. legacy `users.nickname`

### Phase 6 — Chat/Short/Agenda canonical reads
- Commit: `88ecd16` `refactor: align chat short and agenda user reads to canonical fields`
- Updated chat mentions + multiple profile read points to canonical-first with fallback.

### Phase 7 — Education/Job controller completion
- Commit: `7f1ecd6` `refactor: normalize user profile reads in education and job flows`
- Updated remaining controllers for canonical profile fields with legacy fallback.

### Phase 8 — Remaining education controller finalization
- Commit: `aaf37e8` `refactor: finalize canonical user fields in remaining education controllers`
- Updated antreman/optical/tutoring/application review remaining flows.

### Phase 9 — View-layer canonical display finalization
- Commit: `8189675` `refactor: align education profile display to canonical user fields`
- Updated scholarships/tutoring/antreman views for canonical-first avatar/name rendering.

## Root Collection Policy (kept)
Most-used collections intentionally remain at root:
- `users`
- `Posts`
- `conversations`
- `stories`
- `educators`
- `practiceExams`

## Migration + Runtime Notes
- Scholarship runtime now reads from `catalog/education/scholarships`.
- Root `scholarships` collection still exists for rollback safety.
- Users reads are canonical-first, legacy-compatible (no hard break expected).

## Verification Snapshot
- `npm run build` (functions): passed on updated commits.
- Multiple targeted `flutter analyze` runs: passed after each patch set.
- Scholarship migration counts validated with source/target id parity.

## Rollback Strategy
- Full rollback to pre-cutover state: `3abcc34`.
- Logical rollback points by phase:
  - Scholarship path cutover: revert `79044bb`
  - Users alignment bundle: revert commits `e790a0f..8189675` as needed
- Root scholarships data retained, enabling emergency path fallback.
