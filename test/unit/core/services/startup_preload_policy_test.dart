import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/startup_preload_policy.dart';

void main() {
  group('readySegmentsForAheadOffset', () {
    test(
        'keeps active on two segments and forward neighbors first-segment only',
        () {
      expect(StartupPreloadPolicy.readySegmentsForAheadOffset(0), 2);
      for (var offset = 1; offset <= 5; offset++) {
        expect(
          StartupPreloadPolicy.readySegmentsForAheadOffset(offset),
          1,
          reason: 'forward offset $offset should stay first-segment only',
        );
      }
      expect(StartupPreloadPolicy.readySegmentsForAheadOffset(6), 0);
    });
  });

  group('warmReadySegmentsForOffset', () {
    test('keeps mobile feed horizon aligned with wifi first-segment neighbors',
        () {
      expect(
        StartupPreloadPolicy.warmReadySegmentsForOffset(
          0,
          isAndroid: true,
          isOnCellular: true,
        ),
        2,
      );
      expect(
        StartupPreloadPolicy.warmReadySegmentsForOffset(
          1,
          isAndroid: true,
          isOnCellular: true,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.warmReadySegmentsForOffset(
          3,
          isAndroid: true,
          isOnCellular: true,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.warmReadySegmentsForOffset(
          5,
          isAndroid: true,
          isOnCellular: true,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.warmReadySegmentsForOffset(
          6,
          isAndroid: true,
          isOnCellular: true,
        ),
        0,
      );
    });

    test('keeps wifi feed horizon at active plus five first-segment neighbors',
        () {
      expect(
        StartupPreloadPolicy.warmReadySegmentsForOffset(
          5,
          isAndroid: true,
          isOnCellular: false,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.warmReadySegmentsForOffset(
          6,
          isAndroid: true,
          isOnCellular: false,
        ),
        0,
      );
    });

    test('applies the same feed horizon to iOS', () {
      expect(
        StartupPreloadPolicy.warmReadySegmentsForOffset(
          5,
          isAndroid: false,
          isOnCellular: true,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.warmReadySegmentsForOffset(
          6,
          isAndroid: false,
          isOnCellular: true,
        ),
        0,
      );
      expect(
        StartupPreloadPolicy.warmReadySegmentsForOffset(
          5,
          isAndroid: false,
          isOnCellular: false,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.warmReadySegmentsForOffset(
          6,
          isAndroid: false,
          isOnCellular: false,
        ),
        0,
      );
    });
  });

  group('startupWarmReadySegmentsForRank', () {
    test('keeps mobile startup warm count aligned with wifi playable ranks',
        () {
      expect(
        StartupPreloadPolicy.startupWarmReadySegmentsForRank(
          0,
          isAndroid: true,
          isOnCellular: true,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.startupWarmReadySegmentsForRank(
          3,
          isAndroid: true,
          isOnCellular: true,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.startupWarmReadySegmentsForRank(
          4,
          isAndroid: true,
          isOnCellular: true,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.startupWarmReadySegmentsForRank(
          5,
          isAndroid: true,
          isOnCellular: true,
        ),
        0,
      );
    });

    test('keeps wifi startup warm count at five playable ranks', () {
      expect(
        StartupPreloadPolicy.startupWarmReadySegmentsForRank(
          4,
          isAndroid: true,
          isOnCellular: false,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.startupWarmReadySegmentsForRank(
          5,
          isAndroid: true,
          isOnCellular: false,
        ),
        0,
      );
    });

    test('keeps iOS startup warm counts aligned with Android', () {
      expect(
        StartupPreloadPolicy.startupWarmReadySegmentsForRank(
          4,
          isAndroid: false,
          isOnCellular: true,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.startupWarmReadySegmentsForRank(
          5,
          isAndroid: false,
          isOnCellular: true,
        ),
        0,
      );
      expect(
        StartupPreloadPolicy.startupWarmReadySegmentsForRank(
          4,
          isAndroid: false,
          isOnCellular: false,
        ),
        1,
      );
      expect(
        StartupPreloadPolicy.startupWarmReadySegmentsForRank(
          5,
          isAndroid: false,
          isOnCellular: false,
        ),
        0,
      );
    });
  });
}
