import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Models/posts_model.dart';

void main() {
  group('resolvePrefetchReadySegmentsForPost', () {
    test('keeps normal posts on fallback ready segment target', () {
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
        fallbackReadySegments: 2,
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
    test('fills only the first two uncached segments during quota fill', () {
      final order = buildQuotaFillSegmentOrder(
        totalSegments: 6,
        desiredReadySegments: 2,
      );

      expect(order, <int>[0, 1]);
    });

    test('skips cached first segment and stays inside the quota fill window',
        () {
      final order = buildQuotaFillSegmentOrder(
        totalSegments: 6,
        desiredReadySegments: 2,
        cachedSegmentIndices: const <int>{0},
      );

      expect(order, <int>[1]);
    });
  });

  group('shouldUsePrefetchQuotaFillMode', () {
    test('uses quota fill mode for unwatched wifi jobs', () {
      final result = shouldUsePrefetchQuotaFillMode(
        isOnWiFi: true,
        mobileSeedMode: false,
        watchProgress: 0.0,
      );

      expect(result, isTrue);
    });

    test('keeps watched wifi jobs on watched-priority path', () {
      final result = shouldUsePrefetchQuotaFillMode(
        isOnWiFi: true,
        mobileSeedMode: false,
        watchProgress: 0.42,
      );

      expect(result, isFalse);
    });
  });

  group('feed bank helpers', () {
    test('buildFeedBankDocIds skips the visible head and keeps unseen video docs',
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
