# Performance + Firebase Cost Optimizations (Phase Final)

Date: 2026-03-05
Branch: codex/final-perf-firebase-baseline

## Scope
This checklist finalizes deployment for Phase 2/3 performance and Firebase cost reductions completed after Phase 1.

## Included Commit Range
Start: `77b3d64`
End: `f7aeb2c`

## Key Changes In This Range
1. Admin push user scan reduced with paged/cutoff targeting.
2. Author/profile sync write amplification caps lowered in Cloud Functions.
3. Shorts/Explore/Profile video queries moved toward DB-level `hlsStatus == ready` filtering with safe fallbacks.
4. Agenda background shuffle fetch reduced.
5. User-post link hydration and realtime ref listeners capped and deduped.
6. Scheduled-post queries in profile modules scoped to owner/flags.

## Firestore Index Deploy
1. Preview current index diff:
```bash
git diff -- firestore.indexes.json
```
2. Deploy indexes:
```bash
firebase deploy --only firestore:indexes
```
3. Verify deploy result in Firebase Console:
- Firestore -> Indexes -> Composite
- Ensure newly added `Posts` composite indexes are `Enabled` (not `Building`)

## Staging Validation (Required)
1. Admin push send flow: target count and completion report.
2. Shorts/Explore video tabs: no blank feed and no pagination freeze.
3. MyProfile/SocialProfile scheduled tab: only owner scheduled items.
4. Saved/Liked screens on heavy accounts: first load and refresh latency.
5. Feed refresh/scroll behavior after Agenda shuffle cap changes.

## Production Rollout
1. Rollout window: 5% -> 25% -> 100%.
2. Observe for each step at least 30 minutes before next step.
3. Stop rollout if read/write cost spikes above baseline band.

## 48-Hour Monitoring
1. Firestore Reads per active session (target: down vs baseline).
2. Firestore Writes per active session (target: down vs baseline).
3. Error rate for feed/profile/explore screens.
4. p95 first-content and list pagination latency.

## Rollback
1. Revert last commit only:
```bash
git revert f7aeb2c
```
2. Revert full final range (newest to oldest):
```bash
git revert f7aeb2c 58d06ae b3fed1f 2603cd7 e4e2bf4 557325e d7b2637 613985b 77b3d64
```
3. If urgent, rollback deployment first, then revert commits.

## Exit Criteria
1. Indexes deployed successfully.
2. Staging checklist fully green.
3. Production 48-hour read/write trend improved and stable.
4. No critical regressions in feed/explore/profile/admin flows.
