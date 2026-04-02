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
}
