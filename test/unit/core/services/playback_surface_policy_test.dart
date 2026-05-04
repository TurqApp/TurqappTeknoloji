import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_surface_policy.dart';

void main() {
  group('feed playback surface policy', () {
    test('keeps mobile feed horizon tight on Android and iOS', () {
      expect(
        PlaybackSurfacePolicy.feedWarmFirstSegmentAheadCount(
          platform: TargetPlatform.android,
          isFeedStyleSurface: true,
          isOnCellular: true,
          defaultCount: 99,
        ),
        3,
      );
      expect(
        PlaybackSurfacePolicy.feedWarmFirstSegmentAheadCount(
          platform: TargetPlatform.iOS,
          isFeedStyleSurface: true,
          isOnCellular: true,
          defaultCount: 99,
        ),
        3,
      );
    });

    test('keeps wifi feed horizon wide on Android and iOS', () {
      expect(
        PlaybackSurfacePolicy.feedWarmFirstSegmentAheadCount(
          platform: TargetPlatform.android,
          isFeedStyleSurface: true,
          isOnCellular: false,
          defaultCount: 99,
        ),
        5,
      );
      expect(
        PlaybackSurfacePolicy.feedWarmFirstSegmentAheadCount(
          platform: TargetPlatform.iOS,
          isFeedStyleSurface: true,
          isOnCellular: false,
          defaultCount: 99,
        ),
        5,
      );
    });

    test('locks startup playable counts to mobile and wifi targets', () {
      expect(
        PlaybackSurfacePolicy.feedStartupWarmPlayableCount(
          platform: TargetPlatform.android,
          isOnCellular: true,
          defaultCount: 99,
        ),
        4,
      );
      expect(
        PlaybackSurfacePolicy.feedStartupWarmPlayableCount(
          platform: TargetPlatform.iOS,
          isOnCellular: false,
          defaultCount: 99,
        ),
        6,
      );
    });

    test('keeps autoplay gate aggressively short for feed-style surfaces', () {
      expect(
        PlaybackSurfacePolicy.feedAutoplayGateTimeout(
          platform: TargetPlatform.android,
          isFeedStyleSurface: true,
        ),
        const Duration(milliseconds: 180),
      );
      expect(
        PlaybackSurfacePolicy.feedAutoplayGatePollInterval(
          platform: TargetPlatform.iOS,
          isFeedStyleSurface: true,
        ),
        const Duration(milliseconds: 20),
      );
    });

    test('does not retain iOS feed owner longer than Android-style handoff',
        () {
      expect(
        PlaybackSurfacePolicy.supportsFeedVisibleOwnerRetention(
          platform: TargetPlatform.iOS,
        ),
        isFalse,
      );
      expect(
        PlaybackSurfacePolicy.supportsFeedStartupTargetRetention(
          platform: TargetPlatform.iOS,
        ),
        isFalse,
      );
      expect(
        PlaybackSurfacePolicy.supportsFeedSwitchRetention(
          platform: TargetPlatform.iOS,
        ),
        isFalse,
      );
      expect(
        PlaybackSurfacePolicy.feedCenteredGapPlaybackGrace(
          platform: TargetPlatform.iOS,
          androidDuration: const Duration(milliseconds: 999),
        ),
        const Duration(milliseconds: 220),
      );
    });

    test('prefers direct CDN for primary feed on Android and iOS', () {
      expect(
        PlaybackSurfacePolicy.preferDirectCdnForFeed(
          platform: TargetPlatform.android,
          isPrimaryFeedSurface: true,
        ),
        isTrue,
      );
      expect(
        PlaybackSurfacePolicy.preferDirectCdnForFeed(
          platform: TargetPlatform.iOS,
          isPrimaryFeedSurface: true,
        ),
        isTrue,
      );
      expect(
        PlaybackSurfacePolicy.preferDirectCdnForFeed(
          platform: TargetPlatform.iOS,
          isPrimaryFeedSurface: false,
        ),
        isFalse,
      );
    });
  });

  group('short playback surface policy', () {
    test('keeps short forward warm horizon hot on mobile and wifi', () {
      expect(
        PlaybackSurfacePolicy.shortForwardWarmFirstSegmentAheadCount(
          platform: TargetPlatform.android,
          isOnCellular: true,
          defaultCount: 99,
        ),
        5,
      );
      expect(
        PlaybackSurfacePolicy.shortForwardWarmFirstSegmentAheadCount(
          platform: TargetPlatform.iOS,
          isOnCellular: false,
          defaultCount: 99,
        ),
        6,
      );
    });

    test('keeps short tier timing unified across Android and iOS', () {
      expect(
        PlaybackSurfacePolicy.shortTierDebounceDelay(
          platform: TargetPlatform.android,
          defaultDelay: const Duration(milliseconds: 999),
        ),
        const Duration(milliseconds: 10),
      );
      expect(
        PlaybackSurfacePolicy.shortTierReconcileDelay(
          platform: TargetPlatform.iOS,
          defaultDelay: const Duration(milliseconds: 999),
        ),
        const Duration(milliseconds: 60),
      );
    });

    test('keeps short scroll debounce immediate on iOS', () {
      expect(
        PlaybackSurfacePolicy.shortScrollDebounceDelay(
          platform: TargetPlatform.android,
          androidDelay: const Duration(milliseconds: 70),
        ),
        const Duration(milliseconds: 40),
      );
      expect(
        PlaybackSurfacePolicy.shortScrollDebounceDelay(
          platform: TargetPlatform.iOS,
          androidDelay: const Duration(milliseconds: 70),
        ),
        Duration.zero,
      );
    });

    test('keeps iOS short neighbors at least two ready segments warm', () {
      expect(
        PlaybackSurfacePolicy.shortNeighborReadySegments(
          platform: TargetPlatform.iOS,
          useTightWarmProfile: true,
          defaultCount: 1,
        ),
        2,
      );
      expect(
        PlaybackSurfacePolicy.shortNeighborReadySegments(
          platform: TargetPlatform.iOS,
          useTightWarmProfile: false,
          defaultCount: 3,
        ),
        3,
      );
    });

    test('prefers direct CDN for short surfaces on Android and iOS', () {
      expect(
        PlaybackSurfacePolicy.preferDirectCdnForShort(
          platform: TargetPlatform.android,
        ),
        isTrue,
      );
      expect(
        PlaybackSurfacePolicy.preferDirectCdnForShort(
          platform: TargetPlatform.iOS,
        ),
        isTrue,
      );
    });

    test('keeps iOS short stall and recovery guard values stable', () {
      expect(
        PlaybackSurfacePolicy.shortIosNativePlaybackGuardDelay(attempt: 0),
        const Duration(milliseconds: 1400),
      );
      expect(
        PlaybackSurfacePolicy.shortIosNativePlaybackGuardDelay(attempt: 2),
        const Duration(milliseconds: 900),
      );
      expect(
        PlaybackSurfacePolicy.shortStallMaxRetries(
          platform: TargetPlatform.iOS,
        ),
        4,
      );
      expect(
        PlaybackSurfacePolicy.shortStallMaxRetries(
          platform: TargetPlatform.android,
        ),
        2,
      );
    });
  });
}
