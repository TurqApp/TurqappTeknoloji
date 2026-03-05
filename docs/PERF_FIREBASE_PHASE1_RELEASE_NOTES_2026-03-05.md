# Performance + Firebase Cost Optimizations (Phase 1)

Date: 2026-03-05
Branch: codex/final-perf-firebase-baseline
Baseline Tag: FINAL_PERF_FIREBASE_BASELINE_2026_03_05

## Scope
This phase applies read/write cost reductions in Chat, Feed, and selected N+1 query paths.

## Included Commits
1. `9eefe8c` - perf(chat): reduce typing writes and polling overlap
2. `625686c` - perf(feed): cap reshare scans and batch privacy lookups
3. `931c35f` - perf(reads): replace N+1 user/job lookups with whereIn batches
4. `d13605d` - perf(feed): replace per-card membership streams with one-shot reads
5. `45ac73f` - perf(chat-feed): switch listing refresh to realtime trigger and one-shot follow checks

## User-Visible Changes
1. Typing indicator updates are less write-heavy and may feel slightly less granular.
2. Chat listing refresh behavior is now realtime-triggered instead of frequent polling.
3. Feed card membership state (like/save/reshare/follow) is loaded with one-shot reads.
4. High-volume reshare lists may be more selective under cost guardrails.

## Technical Summary
1. Typing writes changed from near-keystroke frequency to heartbeat/state-transition pattern.
2. Chat and unread flows now prefer realtime + fallback polling, reducing duplicate data pulls.
3. Feed reshare scans now have bounded limits and batched privacy cache warming.
4. N+1 reads in SavedJobs, PostSharers, and FirebaseMyStore were migrated to `whereIn` chunking.
5. Per-card user membership listeners were replaced with one-shot reads in feed/short card controllers.

## Risk Notes
1. Membership state can be less instantly reactive to external device changes.
2. Reshare visibility may refresh with bounded latency due to scan limits.
3. Chat listing can rely more on stream events; fallback timer remains for offline scenarios.

## Rollback Plan
1. Revert latest patch only:
   - `git revert 45ac73f`
2. Revert all Phase 1 patches (newest to oldest):
   - `git revert 45ac73f d13605d 931c35f 625686c 9eefe8c`
3. Hard return to baseline snapshot:
   - `git reset --hard FINAL_PERF_FIREBASE_BASELINE_2026_03_05`

## Pre-Deploy Checklist
1. Validate chat send/receive on two devices (foreground/background).
2. Validate typing indicator start/stop behavior in normal and slow network.
3. Validate unread counters in chat list and global badge.
4. Validate like/save/reshare actions on feed and photo short cards.
5. Validate follow/unfollow state on feed cards and profile transitions.
6. Validate reshare entries appear for followed and public users.
7. Validate SavedJobs, PostSharers, and last searched users load for large lists.
8. Run smoke load (k6) for feed/listing endpoints and compare p95/error rate.
9. Verify Firestore usage trend after rollout window (reads/writes per session).

## Rollout Strategy
1. Deploy to staging and run checklist fully.
2. Production rollout in steps: 5% -> 25% -> 100%.
3. Monitor error rate, read/write spikes, and p95 latency after each step.
4. Keep rollback command ready during each stage.

