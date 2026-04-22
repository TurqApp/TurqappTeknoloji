import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_feed_application_service.dart';

void main() {
  group('AgendaFeedApplicationService', () {
    test('buildPageApplyPlan only adds new posts and marks fresh scheduled ids',
        () {
      final service = AgendaFeedApplicationService();
      final nowMs = DateTime(2026, 3, 28, 12).millisecondsSinceEpoch;
      final existing = <PostsModel>[
        _post(id: 'p1'),
      ];
      final pageItems = <PostsModel>[
        _post(id: 'p1'),
        _post(
            id: 'p2',
            timeStamp: nowMs - const Duration(minutes: 5).inMilliseconds),
        _post(
            id: 'p3',
            timeStamp: nowMs - const Duration(minutes: 20).inMilliseconds),
      ];

      final plan = service.buildPageApplyPlan(
        currentItems: existing,
        pageItems: pageItems,
        nowMs: nowMs,
        loadLimit: 30,
        lastDoc: null,
        hasMore: false,
        usesPrimaryFeed: true,
      );

      expect(plan.itemsToAdd.map((post) => post.docID).toList(),
          <String>['p2', 'p3']);
      expect(plan.freshScheduledIds, <String>['p2']);
      expect(plan.hasMore, isFalse);
      expect(plan.usesPrimaryFeed, isTrue);
    });

    test(
        'buildRefreshPlan keeps current splash list and only prepends new live head posts',
        () {
      final service = AgendaFeedApplicationService();
      final nowMs = DateTime(2026, 4, 2, 12).millisecondsSinceEpoch;
      final currentItems = <PostsModel>[
        _post(id: 'p1'),
        _post(id: 'p2'),
        _post(id: 'p3'),
      ];
      final fetchedPosts = <PostsModel>[
        _post(
          id: 'p4',
          timeStamp: nowMs - const Duration(minutes: 5).inMilliseconds,
        ),
        _post(id: 'p2', timeStamp: nowMs - 1000),
        _post(id: 'p1', timeStamp: nowMs - 2000),
      ];

      final plan = service.buildRefreshPlan(
        currentItems: currentItems,
        fetchedPosts: fetchedPosts,
        nowMs: nowMs,
      );

      expect(
        plan.replacementItems.map((post) => post.docID).toList(),
        <String>['p4', 'p1', 'p2', 'p3'],
      );
      expect(plan.replacementItems[2].timeStamp, nowMs - 1000);
      expect(plan.freshScheduledIds, <String>['p4']);
    });

    test(
        'capturePlaybackAnchor prefers centered index over last centered index',
        () {
      final service = AgendaFeedApplicationService();
      final agendaList = <PostsModel>[
        _post(id: 'p1'),
        _post(id: 'p2'),
      ];

      final anchor = service.capturePlaybackAnchor(
        agendaList: agendaList,
        centeredIndex: 1,
        lastCenteredIndex: 0,
      );

      expect(anchor, 'p2');
    });

    test('resolveInitialCenteredIndex prefers pending doc then first item', () {
      final service = AgendaFeedApplicationService();
      final agendaList = <PostsModel>[
        _post(id: 'p1'),
        _videoPost(id: 'p2'),
        _videoPost(id: 'p3'),
      ];

      expect(
        service.resolveInitialCenteredIndex(
          agendaList: agendaList,
          pendingCenteredDocId: 'p3',
          lastCenteredIndex: null,
          canAutoplayPost: (post) => post.video.isNotEmpty,
        ),
        2,
      );

      expect(
        service.resolveInitialCenteredIndex(
          agendaList: agendaList,
          pendingCenteredDocId: null,
          lastCenteredIndex: null,
          canAutoplayPost: (post) => post.video.isNotEmpty,
        ),
        0,
      );
    });

    test(
        'resolveResumeIndex prefers visible strongest post and keeps non-video current item when nothing is visible',
        () {
      final service = AgendaFeedApplicationService();
      final agendaList = <PostsModel>[
        _post(id: 'p1'),
        _videoPost(id: 'p2'),
        _videoPost(id: 'p3'),
      ];

      expect(
        service.resolveResumeIndex(
          agendaList: agendaList,
          pendingCenteredDocId: null,
          lastCenteredIndex: null,
          centeredIndex: 0,
          visibleFractions: <int, double>{2: 0.8, 1: 0.4},
          canAutoplayPost: (post) => post.video.isNotEmpty,
        ),
        2,
      );

      expect(
        service.resolveResumeIndex(
          agendaList: agendaList,
          pendingCenteredDocId: null,
          lastCenteredIndex: null,
          centeredIndex: 0,
          visibleFractions: const <int, double>{},
          canAutoplayPost: (post) => post.video.isNotEmpty,
        ),
        0,
      );
    });

    test(
        'agenda controller delegates feed orchestration to application service',
        () {
      final feedSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/agenda_controller_feed_part.dart',
      ).readAsStringSync();
      final loadingSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/agenda_controller_loading_part.dart',
      ).readAsStringSync();
      final lifecycleSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/agenda_controller_lifecycle_part.dart',
      ).readAsStringSync();

      expect(
        feedSource,
        contains('_agendaFeedApplicationService.resolveInitialCenteredIndex'),
      );
      expect(
        feedSource,
        contains('_agendaFeedApplicationService.resolveResumeIndex'),
      );
      expect(feedSource, isNot(contains('int _resolveInitialCenteredIndex()')));
      expect(feedSource, isNot(contains('int _resolveResumeIndex()')));
      expect(
        loadingSource,
        contains('_agendaFeedApplicationService.buildPageApplyPlan'),
      );
      expect(
        lifecycleSource,
        contains('_agendaFeedApplicationService.capturePlaybackAnchor'),
      );
    });

    test('capStartupRenderEntries keeps only first six posts and their promos',
        () {
      final service = AgendaFeedApplicationService();
      final renderEntries = List<Map<String, dynamic>>.generate(30, (index) {
        final postNumber = index + 1;
        return <String, dynamic>{
          'renderType': 'post',
          'postNumber': postNumber,
        };
      }).expand((entry) sync* {
        final postNumber = entry['postNumber']! as int;
        yield entry;
        if (postNumber % 3 == 0) {
          yield <String, dynamic>{
            'renderType': 'promo',
            'slotNumber': postNumber ~/ 3,
          };
        }
      }).toList(growable: false);

      final capped = service.capStartupRenderEntries(
        renderEntries: renderEntries,
        visiblePostCount: 6,
      );

      expect(capped.length, 8);
      expect(
        capped.where((entry) => entry['renderType'] == 'post').length,
        6,
      );
      expect(
        capped.where((entry) => entry['renderType'] == 'promo').length,
        2,
      );
      expect(
        capped
            .where((entry) => entry['renderType'] == 'post')
            .map((entry) => entry['postNumber']),
        orderedEquals(<int>[1, 2, 3, 4, 5, 6]),
      );

      final cappedFifteen = service.capStartupRenderEntries(
        renderEntries: renderEntries,
        visiblePostCount: 15,
      );
      expect(
        cappedFifteen.where((entry) => entry['renderType'] == 'post').length,
        15,
      );
      expect(
        cappedFifteen.where((entry) => entry['renderType'] == 'promo').length,
        5,
      );
      expect(cappedFifteen.length, 20);

      final cappedThirty = service.capStartupRenderEntries(
        renderEntries: renderEntries,
        visiblePostCount: 30,
      );
      expect(cappedThirty, orderedEquals(renderEntries));
    });

    test(
        'startup support path keeps flood roots outside the normal time window',
        () {
      final loadingCacheSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Modules/Agenda/agenda_controller_loading_cache_part.dart',
      ).readAsStringSync();
      final repositorySource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/post_repository_query_part.dart',
      ).readAsStringSync();

      expect(
        loadingCacheSource,
        contains(
            "if (kind == 'flood') {\n        primaryCandidates.add(post);"),
      );
      expect(
        repositorySource,
        contains("where('flood', isEqualTo: false)"),
      );
      expect(
        repositorySource,
        contains('if (!model.isFloodSeriesRoot) continue;'),
      );
    });

    test('feed visibility source keeps flood series eligible', () {
      final visibilitySource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/feed_snapshot_repository_visibility_part.dart',
      ).readAsStringSync();
      final repositorySource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/feed_snapshot_repository.dart',
      ).readAsStringSync();

      expect(visibilitySource, isNot(contains('post.isFloodMember')));
      expect(visibilitySource, isNot(contains('flood_child')));
      expect(repositorySource, isNot(contains('post.isFloodMember')));
    });
  });
}

PostsModel _post({
  required String id,
  int timeStamp = 0,
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

PostsModel _videoPost({
  required String id,
  int timeStamp = 0,
}) {
  return _post(id: id, timeStamp: timeStamp)..video = 'video-$id.mp4';
}
