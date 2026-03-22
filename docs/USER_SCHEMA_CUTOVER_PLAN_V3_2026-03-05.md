# User Schema V3 Cutover Plan (No Legacy Fallback)

Date: 2026-03-05
Mode: gradual rollout, strict cutover
Goal: single canonical user schema across app + functions without broken modules.

## Canonical `users/{uid}` Fields
Required:
- `displayName`
- `username`
- `avatarUrl`
- `gizliHesap`
- `accountStatus`
- `createdDate`
- `followerCount`
- `followingCount`
- `postCount`

Optional:
- `bio`, `city`, `isVerified`, `fcmToken`, `role`

## Phase A - Read/Write Contract Freeze
1. Add single `AppUser` mapping contract in one model/service layer.
2. Freeze all new writes to canonical fields only.
3. Update Firestore rules whitelist to canonical update keys.

Exit criteria:
- No new write path creates `nickname/avatarUrl/avatarUrl`.

## Phase B - Functions Alignment
1. `authorDenorm.ts` -> source only `displayName` + `avatarUrl`.
2. `09_userProfile.ts` -> use only canonical fields for post author sync.
3. `14/15_typesense*` -> normalize index fields from canonical names.

Exit criteria:
- Functions build clean.
- Post author denorm still updates correctly.

## Phase C - App Service Layer Alignment
1. `current_user_service.dart`
2. `firebase_my_store.dart`
3. `reshare_helper.dart`
4. common user widgets/helpers

Action:
- remove legacy field reads in service layer; map UI from canonical fields.

Exit criteria:
- Profile, feed card headers, chat headers show correct name/avatar.

## Phase D - Module-by-Module UI/Controller Cutover
Order:
1. Profile + SocialProfile
2. Agenda + Explore + Shorts
3. Chat + Notifications
4. Education/Scholarship screens

For each module:
- replace user field reads with canonical names
- run `flutter analyze` for touched files
- smoke test checklist

## Phase E - Data Migration (3 Users)
1. One-time migration script/update:
- populate canonical fields from existing values
- remove deprecated fields after verification
2. Verify all 3 users in Firebase Console manually.

Verification checklist per user:
- `displayName`, `username`, `avatarUrl` non-empty
- `gizliHesap`, `accountStatus` valid
- counters present

## Phase F - Cleanup Lock
1. Remove all legacy field references from codebase.
2. Confirm grep zero:
- `nickname`
- `avatarUrl`
- `avatarUrl`
- `avatarUrl` (if not part of canonical)
3. Keep rollback tag before final deploy.

## Scholarship Chain Safety Checks (Mandatory)
- Create scholarship
- Edit scholarship
- Scholarship list cards (name/avatar)
- Like/bookmark/apply
- MyScholarship / SavedItems / Applications screens

## Rollback
- Revert latest cutover commit range.
- Restore previous user field mapping in service layer.

