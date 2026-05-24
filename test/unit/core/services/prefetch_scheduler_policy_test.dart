import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Models/posts_model.dart';

void main() {
  group('resolvePrefetchReadySegmentsForPost', () {
    test('caps normal posts at the second ready segment', () {
      final post = PostsModel.fromMap(
        <String, dynamic>{
          'playbackUrl': 'https://cdn.turqapp.com/Posts/doc-1/hls/master.m3u8',
          'rozet': 'user',
          'flood': false,
          'mainFlood': '',
          'floodCount': 0,
        },
        'doc-1',
      );

      final target = resolvePrefetchReadySegmentsForPost(
        post,
        fallbackReadySegments: 4,
      );

      expect(target, 2);
    });

    test('caps flood content to a single ready segment', () {
      final post = PostsModel.fromMap(
        <String, dynamic>{
          'playbackUrl': 'https://cdn.turqapp.com/Posts/doc-2/hls/master.m3u8',
          'rozet': 'user',
          'flood': true,
          'mainFlood': 'series-1',
          'floodCount': 3,
        },
        'doc-2',
      );

      final target = resolvePrefetchReadySegmentsForPost(
        post,
        fallbackReadySegments: 2,
      );

      expect(target, 1);
    });
  });

  group('buildQuotaFillSegmentOrder', () {
    test('returns only the first segment for quota fill', () {
      final order = buildQuotaFillSegmentOrder(
        totalSegments: 6,
        desiredReadySegments: 2,
      );

      expect(order, <int>[0]);
    });

    test('does not continue when the first segment is already cached', () {
      final order = buildQuotaFillSegmentOrder(
        totalSegments: 6,
        desiredReadySegments: 2,
        cachedSegmentIndices: const <int>{0},
      );

      expect(order, isEmpty);
    });
  });

  group('shouldUsePrefetchQuotaFillMode', () {
    test('uses quota fill mode for unwatched wifi jobs', () {
      final result = shouldUsePrefetchQuotaFillMode(
        isOnWiFi: true,
        allowCellularQuotaFill: false,
        mobileSeedMode: false,
        watchProgress: 0.0,
      );

      expect(result, isTrue);
    });

    test('keeps watched wifi jobs on watched-priority path', () {
      final result = shouldUsePrefetchQuotaFillMode(
        isOnWiFi: true,
        allowCellularQuotaFill: false,
        mobileSeedMode: false,
        watchProgress: 0.42,
      );

      expect(result, isFalse);
    });
  });

  group('surface prefetch network policy', () {
    test('allows feed and short surface warmup on cellular playback network',
        () {
      final allowed = shouldAllowSurfacePrefetchNetwork(
        isOnWiFi: false,
        isOnCellular: true,
        canPrefetch: false,
        canFetchOnDemand: true,
        canFetchPlaylist: true,
        cacheOnlyMode: false,
      );

      expect(allowed, isTrue);
      expect(
        shouldAllowPrefetchJobForNetwork(
          source: 'feed',
          surfacePrefetchNetworkEligible: allowed,
          quotaFillNetworkEligible: false,
        ),
        isTrue,
      );
      expect(
        shouldAllowPrefetchJobForNetwork(
          source: 'short',
          surfacePrefetchNetworkEligible: allowed,
          quotaFillNetworkEligible: false,
        ),
        isTrue,
      );
    });

    test('keeps quota fill blocked on cellular while surface warmup is allowed',
        () {
      expect(
        shouldAllowPrefetchJobForNetwork(
          source: 'quota',
          surfacePrefetchNetworkEligible: true,
          quotaFillNetworkEligible: false,
        ),
        isFalse,
      );
    });

    test('respects cache-only cellular guard', () {
      final allowed = shouldAllowSurfacePrefetchNetwork(
        isOnWiFi: false,
        isOnCellular: true,
        canPrefetch: false,
        canFetchOnDemand: false,
        canFetchPlaylist: true,
        cacheOnlyMode: true,
      );

      expect(allowed, isFalse);
    });

    test('uses wifi warm window sizing on cellular playback network', () {
      expect(
        shouldUseWifiSurfaceWarmSettings(
          isOnWiFi: false,
          isOnCellular: true,
        ),
        isTrue,
      );
      expect(
        shouldUseWifiSurfaceWarmSettings(
          isOnWiFi: false,
          isOnCellular: false,
        ),
        isFalse,
      );
    });
  });

  group('feed priority window helpers', () {
    test('keeps follow-up priority inside a single batch only', () {
      expect(
        isPriorityWindowTargetIndex(currentIndex: 2, targetIndex: 4),
        isTrue,
      );
      expect(
        isPriorityWindowTargetIndex(currentIndex: 2, targetIndex: 5),
        isFalse,
      );
    });

    test('scopes feed priority context to the visible window', () {
      final context = resolveFeedPriorityWindowContext(
        docIDs: const <String>[
          'p0',
          'p1',
          'p2',
          'p3',
          'p4',
          'p5',
          'p6',
          'p7',
        ],
        currentIndex: 3,
      );

      expect(
          context.docIDs, <String>['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7']);
      expect(context.currentIndex, 2);
    });

    test('keeps active doc deeper than adjacent feed warm window', () {
      expect(
        resolveFeedWindowReadySegments(currentIndex: 10, targetIndex: 10),
        2,
      );
      expect(
        resolveFeedWindowReadySegments(currentIndex: 10, targetIndex: 11),
        1,
      );
      expect(
        resolveFeedWindowReadySegments(currentIndex: 10, targetIndex: 12),
        1,
      );
      expect(
        resolveFeedWindowReadySegments(currentIndex: 10, targetIndex: 13),
        1,
      );
      expect(
        resolveFeedWindowReadySegments(currentIndex: 10, targetIndex: 14),
        1,
      );
      expect(
        resolveFeedWindowReadySegments(currentIndex: 10, targetIndex: 9),
        1,
      );
      expect(
        resolveFeedWindowReadySegments(currentIndex: 10, targetIndex: 8),
        1,
      );
    });
  });

  group('shouldUseStartupBurstPrefetch', () {
    test('enables startup burst for the active first-segment doc', () {
      final result = shouldUseStartupBurstPrefetch(
        isFocusedDoc: true,
        isCurrentDoc: true,
        watchProgress: 0.0,
        cachedSegmentCount: 0,
        desiredReadySegments: 2,
        totalSegments: 4,
      );

      expect(result, isTrue);
    });

    test('disables startup burst after the first segment window', () {
      final result = shouldUseStartupBurstPrefetch(
        isFocusedDoc: true,
        isCurrentDoc: true,
        watchProgress: 0.45,
        cachedSegmentCount: 1,
        desiredReadySegments: 2,
        totalSegments: 4,
      );

      expect(result, isFalse);
    });

    test('disables startup burst for non-active docs', () {
      final result = shouldUseStartupBurstPrefetch(
        isFocusedDoc: false,
        isCurrentDoc: false,
        watchProgress: 0.0,
        cachedSegmentCount: 0,
        desiredReadySegments: 2,
        totalSegments: 4,
      );

      expect(result, isFalse);
    });
  });

  group('feed bank helpers', () {
    test(
        'buildFeedBankDocIds skips the visible head and keeps unseen video docs',
        () {
      final posts = <PostsModel>[
        _readyPost('p1'),
        _readyPost('p2'),
        _readyPost('p3'),
        _readyPost('p4'),
        _readyPost('p5'),
      ];

      final bank = buildFeedBankDocIds(
        posts: posts,
        currentIndex: 0,
        unseenHeadWindow: 3,
        maxDocs: 10,
      );

      expect(bank, <String>['p4', 'p5']);
    });

    test('merge/prune feed bank doc ids keeps unseen items only', () {
      final posts = <PostsModel>[
        _readyPost('p1'),
        _readyPost('p2'),
        _readyPost('p3'),
        _readyPost('p4'),
      ];

      final pruned = pruneSeenFeedBankDocIds(
        bankDocIds: const <String>['p2', 'p4', 'p5'],
        posts: posts,
        currentIndex: 0,
        seenHeadWindow: 3,
      );
      final merged = mergeFeedBankDocIds(
        existingDocIds: pruned,
        incomingDocIds: const <String>['p6', 'p4'],
        maxDocs: 10,
      );

      expect(pruned, <String>['p4', 'p5']);
      expect(merged, <String>['p6', 'p4', 'p5']);
    });
  });
}

PostsModel _readyPost(String id) => PostsModel.fromMap(
      <String, dynamic>{
        'hlsMasterUrl': 'Posts/$id/hls/master.m3u8',
        'hlsStatus': 'ready',
        'rozet': 'gri',
        'flood': false,
        'mainFlood': '',
        'floodCount': 0,
      },
      id,
    );
