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
        usesPrimaryFeed: true,
      );

      expect(plan.itemsToAdd.map((post) => post.docID).toList(),
          <String>['p2', 'p3']);
      expect(plan.freshScheduledIds, <String>['p2']);
      expect(plan.hasMore, isFalse);
      expect(plan.usesPrimaryFeed, isTrue);
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

    test('resolveInitialCenteredIndex prefers pending doc then first autoplay',
        () {
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
        1,
      );
    });

    test(
        'resolveResumeIndex prefers visible strongest post and falls back to autoplay item',
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
        1,
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
        loadingSource,
        contains('_agendaFeedApplicationService.capturePlaybackAnchor'),
      );
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
