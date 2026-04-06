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

    test('composeStartupFeedItems builds a homogeneous 30-card startup mix',
        () {
      final service = AgendaFeedApplicationService();

      final liveCandidates = List<PostsModel>.generate(
        12,
        (index) => _readyVideoPost(id: 'lv${index + 1}'),
      );
      final cacheCandidates = <PostsModel>[
        ...List<PostsModel>.generate(
          12,
          (index) => _readyVideoPost(id: 'cv${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          12,
          (index) => _imagePost(id: 'im${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          6,
          (index) => _floodPost(id: 'fl${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          4,
          (index) => _textPost(id: 'tx${index + 1}'),
        ),
      ];

      final result = service.composeStartupFeedItems(
        liveCandidates: liveCandidates,
        cacheCandidates: cacheCandidates,
        targetCount: 30,
      );

      expect(result, hasLength(30));
      expect(
        result.map(_startupKindForPost).toList(growable: false),
        const <String>[
          'cache',
          'cache',
          'cache',
          'image',
          'live',
          'live',
          'flood',
          'cache',
          'cache',
          'cache',
          'text',
          'live',
          'live',
          'image',
          'cache',
          'image',
          'image',
          'flood',
          'live',
          'live',
          'image',
          'text',
          'cache',
          'image',
          'live',
          'flood',
          'image',
          'live',
          'image',
          'flood',
        ],
      );
    });

    test(
        'composeStartupFeedItems backfills missing image and text slots with live video first',
        () {
      final service = AgendaFeedApplicationService();

      final liveCandidates = List<PostsModel>.generate(
        20,
        (index) => _readyVideoPost(id: 'lv${index + 1}'),
      );
      final cacheCandidates = <PostsModel>[
        ...List<PostsModel>.generate(
          10,
          (index) => _readyVideoPost(id: 'cv${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          2,
          (index) => _floodPost(id: 'fl${index + 1}'),
        ),
      ];

      final result = service.composeStartupFeedItems(
        liveCandidates: liveCandidates,
        cacheCandidates: cacheCandidates,
        targetCount: 30,
      );

      expect(result, hasLength(30));
      expect(
        result.where((post) => _startupKindForPost(post) == 'image'),
        isEmpty,
      );
      expect(
        result.where((post) => _startupKindForPost(post) == 'text'),
        isEmpty,
      );
      expect(
        result.where((post) => _startupKindForPost(post) == 'live').length,
        20,
      );
      expect(
        result.where((post) => _startupKindForPost(post) == 'cache').length,
        8,
      );
      expect(
        result.where((post) => _startupKindForPost(post) == 'flood').length,
        2,
      );
    });

    test(
        'composeStartupFeedItems keeps flood count bounded when videos can fill missing slots',
        () {
      final service = AgendaFeedApplicationService();

      final liveCandidates = List<PostsModel>.generate(
        20,
        (index) => _readyVideoPost(id: 'lv${index + 1}'),
      );
      final cacheCandidates = <PostsModel>[
        ...List<PostsModel>.generate(
          12,
          (index) => _readyVideoPost(id: 'cv${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          20,
          (index) => _floodPost(id: 'fl${index + 1}'),
        ),
      ];

      final result = service.composeStartupFeedItems(
        liveCandidates: liveCandidates,
        cacheCandidates: cacheCandidates,
        targetCount: 30,
      );

      expect(result, hasLength(30));
      expect(
        result.where((post) => _startupKindForPost(post) == 'flood').length,
        4,
      );
      expect(
        result.where((post) => _startupKindForPost(post) == 'live').length,
        greaterThanOrEqualTo(8),
      );
      expect(
        result
            .where(
              (post) =>
                  _startupKindForPost(post) == 'live' ||
                  _startupKindForPost(post) == 'cache',
            )
            .length,
        26,
      );
    });

    test(
        'mergeStartupHeadWithCurrentItems keeps mixed startup head and preserves unique tail items',
        () {
      final service = AgendaFeedApplicationService();
      final nowMs = DateTime(2026, 4, 2, 15).millisecondsSinceEpoch;

      final currentItems = <PostsModel>[
        _readyVideoPost(id: 'cv1'),
        _readyVideoPost(id: 'cv2'),
        _imagePost(id: 'im1'),
        _textPost(id: 'tx1'),
        _floodPost(id: 'fl1'),
        _readyVideoPost(id: 'cv3'),
      ];
      final updatedCv2 = _readyVideoPost(
        id: 'cv2',
        timeStamp: nowMs - const Duration(minutes: 1).inMilliseconds,
      );
      final liveItems = <PostsModel>[
        _readyVideoPost(id: 'lv1'),
        _readyVideoPost(id: 'lv2'),
        updatedCv2,
      ];

      final merged = service.mergeStartupHeadWithCurrentItems(
        currentItems: currentItems,
        liveItems: liveItems,
        targetCount: 6,
        nowMs: nowMs,
      );
      final expectedHead = service.composeStartupFeedItems(
        liveCandidates: liveItems,
        cacheCandidates: <PostsModel>[
          _readyVideoPost(id: 'cv1'),
          updatedCv2,
          _imagePost(id: 'im1'),
          _textPost(id: 'tx1'),
          _floodPost(id: 'fl1'),
          _readyVideoPost(id: 'cv3'),
        ],
        targetCount: 6,
      );

      expect(
        merged.take(6).map((post) => post.docID).toList(growable: false),
        expectedHead.map((post) => post.docID).toList(growable: false),
      );
      expect(
        merged.map((post) => post.docID).toSet().length,
        merged.length,
      );
      expect(
        merged.firstWhere((post) => post.docID == 'cv2').timeStamp,
        updatedCv2.timeStamp,
      );
      expect(
        merged.any((post) => post.docID == 'tx1'),
        isTrue,
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

PostsModel _readyVideoPost({
  required String id,
  int timeStamp = 0,
}) {
  return _post(id: id, timeStamp: timeStamp)
    ..video = 'https://cdn.example.com/$id/master.m3u8'
    ..hlsMasterUrl = 'https://cdn.example.com/$id/master.m3u8'
    ..hlsStatus = 'ready'
    ..thumbnail = 'https://cdn.example.com/$id/thumb.jpg';
}

PostsModel _imagePost({
  required String id,
  int timeStamp = 0,
}) {
  return _post(id: id, timeStamp: timeStamp)
    ..img = <String>['https://cdn.example.com/$id.jpg'];
}

PostsModel _textPost({
  required String id,
  int timeStamp = 0,
}) {
  return _post(id: id, timeStamp: timeStamp)..metin = 'text-$id';
}

PostsModel _floodPost({
  required String id,
  int timeStamp = 0,
}) {
  return _post(id: id, timeStamp: timeStamp)
    ..floodCount = 3
    ..thumbnail = 'https://cdn.example.com/$id-thumb.jpg';
}

String _startupKindForPost(PostsModel post) {
  if (post.docID.startsWith('lv')) return 'live';
  if (post.docID.startsWith('cv')) return 'cache';
  if (post.docID.startsWith('im')) return 'image';
  if (post.docID.startsWith('fl')) return 'flood';
  if (post.docID.startsWith('tx')) return 'text';
  return 'other';
}
