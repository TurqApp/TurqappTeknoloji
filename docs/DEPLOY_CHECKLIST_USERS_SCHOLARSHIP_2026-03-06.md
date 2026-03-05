# Deploy Checklist — Users Canonical + Scholarship Catalog Path

Date: 2026-03-06
Target branch: `codex/final-perf-firebase-baseline`
Latest commit: `8189675`

## A) Pre-Deploy
1. Confirm local branch and cleanliness
- `git rev-parse --abbrev-ref HEAD`
- `git status --short` (must be empty)

2. Verify commit range on branch
- `git log --oneline 3abcc34..HEAD`

3. Build checks
- App: targeted `flutter analyze` already clean
- Functions: `cd functions && npm run build`

## B) Push
1. Push branch
- `git push -u origin codex/final-perf-firebase-baseline`

2. Tag optional rollback anchors
- `git tag users-cutover-v1 8189675`
- `git tag scholarships-catalog-cutover 79044bb`
- `git push origin --tags`

## C) Firebase Deploy Order
1. Firestore rules
- `firebase deploy --only firestore:rules`

2. Firestore indexes
- `firebase deploy --only firestore:indexes`

3. Functions (targeted first)
- `firebase deploy --only functions:shortLinksIndex,functions:denormAuthorOnPostWrite,functions:syncAuthorFieldsOnProfileUpdate,functions:onTutoringApplicationCreate,functions:onTutoringApplicationUpdate`

4. Functions full (if needed)
- `firebase deploy --only functions`

## D) Mandatory Smoke Tests (Production)

### D1. Scholarship chain
1. Scholarship list loads with profile name/avatar.
2. Scholarship detail opens from list and from short link.
3. Create scholarship -> appears under new path.
4. Edit scholarship -> persists and reopens correctly.
5. Apply/Save/Like flows work.
6. MyScholarship/SavedItems/Applications pages render owner identity correctly.

### D2. Users canonical chain
1. Profile pages show expected name/avatar (`displayName/avatarUrl`).
2. Story row and story mention profile routing works.
3. Chat listing/message header/profile previews render correct identity.
4. Agenda/Short feed cards and mention taps route correctly.

### D3. Notifications + denorm
1. Post author fields update on new post create.
2. Profile update sync reflects on recent post author labels.
3. Tutoring and Job application notifications show correct applicant label/avatar.

## E) Cost/Performance Watch (First 24h)
1. Firestore reads for `users` and scholarship flows (check spike anomalies).
2. Function invocation/error rate for updated triggers.
3. Client crash/log anomalies on updated screens.

## F) Rollback
1. Fast rollback of latest wave:
- `git revert 8189675`
- continue reverting backward as needed (`aaf37e8`, `7f1ecd6`, ...)

2. Full rollback to checkpoint:
- reset deployment target to commit `3abcc34` and redeploy rules/functions/app.

3. Data rollback safety:
- Root `scholarships` still preserved (no hard delete performed).

## G) Post-Deploy Cleanup (optional, delayed)
1. Keep dual compatibility for a stabilization window.
2. After stable period, evaluate whether root `scholarships` can be archived/cleaned.
3. Remove remaining legacy-only display keys in low-traffic screens if any remain.
