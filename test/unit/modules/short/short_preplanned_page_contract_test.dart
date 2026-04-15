import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Short/short_feed_application_service.dart';

void main() {
  group('Short preplanned page contract', () {
    final anchorMs = DateTime(2026, 4, 14, 18, 27).millisecondsSinceEpoch;

    test('buildInitialLoadPlan preserves preplanned snapshot order', () {
      final service = ShortFeedApplicationService(
        nowMsProvider: () => anchorMs,
      );
      final snapshotPosts = <PostsModel>[
        _post(id: 's-1827', timeStamp: anchorMs),
        _post(
          id: 's-1825',
          timeStamp: DateTime(2026, 4, 14, 18, 25).millisecondsSinceEpoch,
        ),
        _post(
          id: 's-1825',
          timeStamp: DateTime(2026, 4, 14, 18, 25).millisecondsSinceEpoch,
        ),
      ];

      final plan = service.buildInitialLoadPlan(
        currentShorts: const <PostsModel>[],
        snapshotPosts: snapshotPosts,
        isEligiblePost: (_) => true,
        snapshotPostsPreplanned: true,
      );

      expect(
        plan.replacementItems
            ?.map((post) => post.docID)
            .toList(growable: false),
        <String>['s-1827', 's-1825'],
      );
      expect(plan.shouldScheduleBackgroundRefresh, isTrue);
    });

    test('buildRefreshPlan preserves preplanned fetch order', () {
      final service = ShortFeedApplicationService(
        nowMsProvider: () => anchorMs,
      );
      final previousShorts = <PostsModel>[
        _post(id: 'current', timeStamp: anchorMs - 1000),
      ];
      final fetchedPosts = <PostsModel>[
        _post(id: 'current', timeStamp: anchorMs),
        _post(
          id: 's-1827',
          timeStamp: DateTime(2026, 4, 14, 18, 27).millisecondsSinceEpoch,
        ),
        _post(
          id: 's-1825',
          timeStamp: DateTime(2026, 4, 14, 18, 25).millisecondsSinceEpoch,
        ),
      ];

      final plan = service.buildRefreshPlan(
        previousShorts: previousShorts,
        fetchedPosts: fetchedPosts,
        previousIndex: 0,
        fetchedPostsPreplanned: true,
      );

      expect(
        plan.replacementItems.map((post) => post.docID).toList(growable: false),
        <String>['current', 's-1827', 's-1825'],
      );
      expect(plan.remappedIndex, 0);
    });

    test('buildAppendPlan preserves preplanned incoming order', () {
      final service = ShortFeedApplicationService(
        nowMsProvider: () => anchorMs,
      );
      final currentShorts = <PostsModel>[
        _post(id: 'current', timeStamp: anchorMs),
      ];
      final fetchedPosts = <PostsModel>[
        _post(
          id: 's-1827',
          timeStamp: DateTime(2026, 4, 14, 18, 27).millisecondsSinceEpoch,
        ),
        _post(
          id: 's-1825',
          timeStamp: DateTime(2026, 4, 14, 18, 25).millisecondsSinceEpoch,
        ),
        _post(
          id: 's-1825',
          timeStamp: DateTime(2026, 4, 14, 18, 25).millisecondsSinceEpoch,
        ),
      ];

      final plan = service.buildAppendPlan(
        currentShorts: currentShorts,
        fetchedPosts: fetchedPosts,
        isEligiblePost: (_) => true,
        fetchedPostsPreplanned: true,
      );

      expect(
        plan.itemsToAppend.map((post) => post.docID).toList(growable: false),
        <String>['s-1827', 's-1825'],
      );
    });
  });
}

PostsModel _post({
  required String id,
  required int timeStamp,
}) {
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
    thumbnail: '',
    timeStamp: timeStamp,
    userID: 'u1',
    video: 'video',
    yorum: true,
  );
}
