import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_feed_application_service.dart';

void main() {
  group('Feed preplanned page contract', () {
    final anchorMs = DateTime(2026, 4, 14, 18, 27).millisecondsSinceEpoch;

    test('buildPageApplyPlan normalizes preplanned page newest-first', () {
      final service = AgendaFeedApplicationService(
        nowMsProvider: () => anchorMs,
      );
      final pageItems = <PostsModel>[
        _post(
          id: 'p-1825',
          timeStamp: DateTime(2026, 4, 14, 18, 25).millisecondsSinceEpoch,
        ),
        _post(id: 'p-1827', timeStamp: anchorMs),
        _post(
          id: 'p-1818',
          timeStamp: DateTime(2026, 4, 14, 18, 18).millisecondsSinceEpoch,
        ),
      ];

      final plan = service.buildPageApplyPlan(
        currentItems: const <PostsModel>[],
        pageItems: pageItems,
        nowMs: anchorMs,
        loadLimit: 30,
        lastDoc: null,
        usesPrimaryFeed: true,
        pageItemsPreplanned: true,
      );

      expect(
        plan.itemsToAdd.map((post) => post.docID).toList(growable: false),
        <String>['p-1827', 'p-1825', 'p-1818'],
      );
      expect(plan.pageItemsPreplanned, isTrue);
    });

    test('buildPageApplyPlan normalizes non-preplanned page newest-first', () {
      final service = AgendaFeedApplicationService(
        nowMsProvider: () => anchorMs,
      );
      final pageItems = <PostsModel>[
        _post(
          id: 'p-1818',
          timeStamp: DateTime(2026, 4, 14, 18, 18).millisecondsSinceEpoch,
        ),
        _post(id: 'p-1827', timeStamp: anchorMs),
        _post(
          id: 'p-1825',
          timeStamp: DateTime(2026, 4, 14, 18, 25).millisecondsSinceEpoch,
        ),
      ];

      final plan = service.buildPageApplyPlan(
        currentItems: const <PostsModel>[],
        pageItems: pageItems,
        nowMs: anchorMs,
        loadLimit: 30,
        lastDoc: null,
        usesPrimaryFeed: true,
      );

      expect(
        plan.itemsToAdd.map((post) => post.docID).toList(growable: false),
        <String>['p-1827', 'p-1825', 'p-1818'],
      );
      expect(plan.pageItemsPreplanned, isFalse);
    });

    test('mergeLiveItemsPreservingCurrentOrder keeps merged list newest-first',
        () {
      final service = AgendaFeedApplicationService(
        nowMsProvider: () => anchorMs,
      );
      final currentItems = <PostsModel>[
        _post(
          id: 'current',
          timeStamp: DateTime(2026, 4, 14, 18, 26, 30).millisecondsSinceEpoch,
        ),
      ];
      final liveItems = <PostsModel>[
        _post(
          id: 'current',
          timeStamp: DateTime(2026, 4, 14, 18, 26, 30).millisecondsSinceEpoch,
        ),
        _post(
          id: 'p-1827',
          timeStamp: DateTime(2026, 4, 14, 18, 27).millisecondsSinceEpoch,
        ),
        _post(
          id: 'p-1825',
          timeStamp: DateTime(2026, 4, 14, 18, 25).millisecondsSinceEpoch,
        ),
      ];

      final merged = service.mergeLiveItemsPreservingCurrentOrder(
        currentItems: currentItems,
        liveItems: liveItems,
        liveItemsPreplanned: true,
      );

      expect(
        merged.map((post) => post.docID).toList(growable: false),
        <String>['p-1827', 'current', 'p-1825'],
      );
      expect(merged.map((post) => post.timeStamp).toList(growable: false), [
        DateTime(2026, 4, 14, 18, 27).millisecondsSinceEpoch,
        DateTime(2026, 4, 14, 18, 26, 30).millisecondsSinceEpoch,
        DateTime(2026, 4, 14, 18, 25).millisecondsSinceEpoch,
      ]);
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
    video: '',
    yorum: true,
  );
}
