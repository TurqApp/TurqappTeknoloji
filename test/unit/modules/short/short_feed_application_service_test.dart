import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Short/short_feed_application_service.dart';

void main() {
  group('ShortFeedApplicationService', () {
    test(
        'buildInitialLoadPlan uses eligible snapshot when current list is empty',
        () {
      final service = ShortFeedApplicationService();
      final plan = service.buildInitialLoadPlan(
        currentShorts: const <PostsModel>[],
        snapshotPosts: <PostsModel>[
          _short('s1'),
          _imagePost('i1'),
        ],
        isEligiblePost: (post) => post.video.isNotEmpty,
      );

      expect(plan.replacementItems?.map((post) => post.docID).toList(),
          <String>['s1']);
      expect(plan.shouldScheduleBackgroundRefresh, isTrue);
      expect(plan.shouldBootstrapNextPage, isFalse);
    });

    test('buildRefreshPlan remaps selected index by previous doc id', () {
      final service = ShortFeedApplicationService();
      final plan = service.buildRefreshPlan(
        previousShorts: <PostsModel>[_short('s1'), _short('s2')],
        fetchedPosts: <PostsModel>[_short('s2'), _short('s3')],
        previousIndex: 1,
      );

      expect(plan.replacementItems.map((post) => post.docID).toList(),
          <String>['s2', 's3']);
      expect(plan.remappedIndex, 0);
    });

    test('buildAppendPlan deduplicates while preserving repository order', () {
      final service = ShortFeedApplicationService();
      final plan = service.buildAppendPlan(
        currentShorts: const <PostsModel>[],
        fetchedPosts: <PostsModel>[_short('s1'), _short('s2')],
        isEligiblePost: (post) => post.video.isNotEmpty,
      );

      expect(plan.itemsToAppend.map((post) => post.docID).toList(),
          <String>['s1', 's2']);
    });

    test(
        'short controller delegates initial and refresh orchestration to application service',
        () {
      final source = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/Short/short_controller_loading_part.dart',
      ).readAsStringSync();

      expect(source,
          contains('_shortFeedApplicationService.buildInitialLoadPlan'));
      expect(source, contains('_shortFeedApplicationService.buildRefreshPlan'));
      expect(source, contains('_shortFeedApplicationService.buildAppendPlan'));
      expect(source, isNot(contains('bool _applySnapshotResource(')));
    });
  });
}

PostsModel _short(String id) {
  return PostsModel(
    ad: false,
    arsiv: false,
    aspectRatio: 0.8,
    debugMode: false,
    deletedPost: false,
    deletedPostTime: 0,
    docID: id,
    flood: false,
    floodCount: 0,
    gizlendi: false,
    img: const <String>[],
    isAd: false,
    izBirakYayinTarihi: 0,
    konum: '',
    mainFlood: '',
    metin: '',
    originalPostID: '',
    originalUserID: '',
    paylasGizliligi: 0,
    scheduledAt: 0,
    sikayetEdildi: false,
    stabilized: true,
    stats: PostStats(),
    tags: const <String>[],
    thumbnail: 'thumb.webp',
    timeStamp: 0,
    userID: 'u1',
    video: 'video.mp4',
    yorum: true,
  );
}

PostsModel _imagePost(String id) {
  return PostsModel(
    ad: false,
    arsiv: false,
    aspectRatio: 1,
    debugMode: false,
    deletedPost: false,
    deletedPostTime: 0,
    docID: id,
    flood: false,
    floodCount: 0,
    gizlendi: false,
    img: const <String>['image.webp'],
    isAd: false,
    izBirakYayinTarihi: 0,
    konum: '',
    mainFlood: '',
    metin: '',
    originalPostID: '',
    originalUserID: '',
    paylasGizliligi: 0,
    scheduledAt: 0,
    sikayetEdildi: false,
    stabilized: true,
    stats: PostStats(),
    tags: const <String>[],
    thumbnail: '',
    timeStamp: 0,
    userID: 'u1',
    video: '',
    yorum: true,
  );
}
