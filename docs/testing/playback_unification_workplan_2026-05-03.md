# Playback Unification Workplan

Date: 2026-05-03
Branch: `work/yeni-calisma-20260503`

## Goal

Unify playback behavior across:

- Android mobile
- Android Wi-Fi
- iOS mobile
- iOS Wi-Fi

for:

- feed family
- profile family
- flood / explore series / classic inline surfaces
- short

with one rule:

- same behavioral intent everywhere
- keep iOS-only behavior only when it is measurably better

## Current Baseline

### Already unified well

- Android feed family uses a tight warm/startup profile
- Android Wi-Fi now shares most of the Android mobile startup/warm behavior
- Android feed family and profile family already share feed-style playback
- Android short now uses the same fast timing profile on Wi-Fi as mobile

### Still materially different

#### iOS feed family

Files:

- `lib/Modules/Agenda/agenda_controller_feed_part.dart`
- `lib/Modules/Agenda/agenda_controller_playback_part.dart`
- `lib/Modules/Agenda/Common/post_content_base.dart`
- `lib/Modules/Agenda/Common/post_content_base_lifecycle_part.dart`
- `lib/Modules/Agenda/Common/post_content_base_playback_part.dart`

Observed difference classes:

- iOS-only startup and refresh playback locks
- iOS-only immediate handoff preference
- iOS-only cold-start layout / visibility stabilization guards
- iOS-only resume normalization and recovery authority
- iOS-only stall watchdog and native playback recovery branches
- iOS-only stable startup buffer usage on some feed-style surfaces

#### iOS short

Files:

- `lib/Modules/Short/short_view_playback_part.dart`
- `lib/Modules/Short/short_controller_cache_part.dart`
- `lib/Modules/Short/short_controller_runtime_part.dart`
- `lib/Modules/Short/short_controller_loading_part.dart`

Observed difference classes:

- iOS native playback guard timer
- iOS audibility reassert logic
- iOS warm-neighbor and retry behavior
- iOS-specific short startup/play recovery
- cellular render freeze / low-data behavior

## Working Matrix

### Feed family

| Axis | Android mobile | Android Wi-Fi | iOS mobile | iOS Wi-Fi |
|---|---:|---:|---:|---:|
| Forward warm horizon | `+3` | `+5` | wider / legacy mixed | wider / legacy mixed |
| Startup warm playable count | `4` | `6` | legacy mixed | legacy mixed |
| Autoplay required segments | `1` | `1` | native/iOS path | native/iOS path |
| Gate timeout / poll | `250ms / 40ms` | `250ms / 40ms` | iOS-specific | iOS-specific |
| Direct CDN | yes | yes | no comparable override | no comparable override |
| Quota fill | off | minimal on | n/a | n/a |
| Native warm ahead strength | `+2` strong | `+5` strong | different path | different path |

### Short

| Axis | Android mobile | Android Wi-Fi | iOS mobile | iOS Wi-Fi |
|---|---:|---:|---:|---:|
| Tier debounce / reconcile | `20ms / 90ms` | `20ms / 90ms` | iOS-specific | iOS-specific |
| Forward warm horizon | `+2` | `+5` | iOS-specific | iOS-specific |
| Direct CDN | yes | yes | no comparable override | no comparable override |
| Render freeze / low-data guard | mobile only | no | mobile only | no |

## iOS Behaviors Worth Preserving If Better

These should not be removed blindly:

1. Cold-start layout jitter guard
2. Immediate handoff if it measurably reduces visible stalls
3. Resume normalization if it reduces jump/cut feeling
4. Native recovery authority if it prevents frozen-but-visible playback
5. Stable startup buffer usage if it reduces black-frame exposure without adding long startup delay

## Refactor Plan

### Phase A: Inventory and policy axes

Goal:

- convert the current scattered conditionals into a single policy vocabulary

Outputs:

- this workplan
- one policy matrix for feed family
- one policy matrix for short

### Phase B: Central policy object

Add a central policy layer that answers:

- warm horizon
- startup warm count
- required autoplay segments
- autoplay gate timeout
- autoplay gate poll
- direct CDN preference
- quota fill mode
- short tier debounce
- short tier reconcile
- native warm ahead strength

### Phase C: Feed family unification

Apply the central policy to:

- feed
- takip ettiklerim
- şehrim
- classic
- flood
- explore series
- own profile
- social profile

Target:

- Android and iOS follow the same behavioral contract
- iOS implementation may keep better native guardrails

### Phase D: Short unification

Apply the same policy vocabulary to:

- startup timing
- neighbor warm
- direct CDN preference
- short tier timing
- native guard / recovery

Target:

- Android and iOS short feel aligned
- iOS-specific safety remains only if it improves playback

### Phase E: Quota/background discipline

Verify:

- feed active => short quota work does not create unnecessary pressure
- active window restrictions are respected
- mobile remains stricter than Wi-Fi only where intended

## Test Program

Run for each of:

- Android mobile
- Android Wi-Fi
- iOS mobile
- iOS Wi-Fi

Scenarios:

1. feed cold open
2. feed rapid swipe
3. feed backward swipe
4. own profile swipe
5. social profile swipe
6. flood swipe
7. explore series swipe
8. short rapid swipe
9. tab switch return
10. long mixed session

Log focus:

- `FeedPlayWindow`
- `HLSController event=error`
- `firstFrame`
- `sourceRetry`
- `ShortQuotaFill`
- `HlsOffscreenLeak`
- `FeedOnYukleme`

## Immediate Next Step

Implement Phase B:

- create a shared playback policy layer for Android/iOS + mobile/Wi-Fi
- move the current feed/short startup and warm decisions into that layer
