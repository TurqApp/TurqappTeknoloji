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
          'image',
          'live',
          'live',
          'flood',
          'cache',
          'cache',
          'text',
          'live',
          'cache',
          'cache',
          'image',
          'live',
          'live',
          'flood',
          'cache',
          'cache',
          'text',
          'live',
          'cache',
          'cache',
          'image',
          'live',
          'live',
          'flood',
          'cache',
          'cache',
          'text',
          'live',
        ],
      );
    });

    test(
        'composeStartupFeedItems repeats the locked ten-slot motif across sixty cards',
        () {
      final service = AgendaFeedApplicationService();

      final liveCandidates = List<PostsModel>.generate(
        80,
        (index) => _readyVideoPost(id: 'lv${index + 1}'),
      );
      final cacheCandidates = <PostsModel>[
        ...List<PostsModel>.generate(
          80,
          (index) => _readyVideoPost(id: 'cv${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          20,
          (index) => _imagePost(id: 'im${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          12,
          (index) => _floodPost(id: 'fl${index + 1}'),
        ),
      ];

      final result = service.composeStartupFeedItems(
        liveCandidates: liveCandidates,
        cacheCandidates: cacheCandidates,
        targetCount: 60,
      );

      expect(result, hasLength(60));
      _expectLockedTenSlotMotif(result);
    });

    test(
        'composeStartupFeedItems keeps the same locked ten-slot motif across ninety cards',
        () {
      final service = AgendaFeedApplicationService();

      final liveCandidates = List<PostsModel>.generate(
        120,
        (index) => _readyVideoPost(id: 'lv${index + 1}'),
      );
      final cacheCandidates = <PostsModel>[
        ...List<PostsModel>.generate(
          120,
          (index) => _readyVideoPost(id: 'cv${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          30,
          (index) => _imagePost(id: 'im${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          18,
          (index) => _floodPost(id: 'fl${index + 1}'),
        ),
      ];

      final result = service.composeStartupFeedItems(
        liveCandidates: liveCandidates,
        cacheCandidates: cacheCandidates,
        targetCount: 90,
      );

      expect(result, hasLength(90));
      _expectLockedTenSlotMotif(result);
    });

    test(
        'composeStartupFeedItems keeps slot kinds but varies selected posts across startup variants',
        () {
      final service = AgendaFeedApplicationService();

      final liveCandidates = List<PostsModel>.generate(
        40,
        (index) => _readyVideoPost(id: 'lv${index + 1}'),
      );
      final cacheCandidates = <PostsModel>[
        ...List<PostsModel>.generate(
          40,
          (index) => _readyVideoPost(id: 'cv${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          40,
          (index) => _imagePost(id: 'im${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          20,
          (index) => _floodPost(id: 'fl${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          12,
          (index) => _textPost(id: 'tx${index + 1}'),
        ),
      ];

      final variantA = service.composeStartupFeedItems(
        liveCandidates: liveCandidates,
        cacheCandidates: cacheCandidates,
        targetCount: 30,
        startupVariantOverride: 17,
      );
      final variantB = service.composeStartupFeedItems(
        liveCandidates: liveCandidates,
        cacheCandidates: cacheCandidates,
        targetCount: 30,
        startupVariantOverride: 231,
      );

      expect(variantA, hasLength(30));
      expect(variantB, hasLength(30));
      expect(
        variantA.map(_startupKindForPost).toList(growable: false),
        variantB.map(_startupKindForPost).toList(growable: false),
      );
      expect(
        variantA.map((post) => post.docID).toList(growable: false),
        isNot(variantB.map((post) => post.docID).toList(growable: false)),
      );
    });

    test(
        'composeStartupFeedItems prefers flood before video for missing image and text slots',
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
        result.where((post) => _startupKindForPost(post) == 'flood').length,
        2,
      );
      expect(
        result.where((post) => _startupKindForPost(post) == 'live').length,
        18,
      );
      expect(
        result.where((post) => _startupKindForPost(post) == 'cache').length,
        10,
      );
    });

    test(
        'composeStartupFeedItems keeps flood at one per ten and falls back to video when image and text are missing',
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
        3,
      );
      expect(
        result.where((post) => _startupKindForPost(post) == 'live').length,
        15,
      );
      expect(
        result.where((post) => _startupKindForPost(post) == 'cache').length,
        12,
      );
    });

    test(
        'composeStartupFeedItems reserves flood for flood slots before text and image fallbacks',
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
          4,
          (index) => _floodPost(id: 'fl${index + 1}'),
        ),
      ];

      final result = service.composeStartupFeedItems(
        liveCandidates: liveCandidates,
        cacheCandidates: cacheCandidates,
        targetCount: 30,
      );
      final kinds = result.map(_startupKindForPost).toList(growable: false);

      expect(result, hasLength(30));
      expect(kinds.where((kind) => kind == 'flood').length, 3);
      expect(kinds[5], 'flood');
      expect(kinds[15], 'flood');
      expect(kinds[25], 'flood');
      expect(kinds[2], isNot('flood'));
      expect(kinds[8], isNot('flood'));
      expect(kinds[12], isNot('flood'));
      expect(kinds[18], isNot('flood'));
      expect(kinds[22], isNot('flood'));
    });

    test(
        'composeStartupFeedItems keeps flood members out of video buckets and at one flood per ten',
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
          8,
          (index) => _floodMemberVideoPost(id: 'flm${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          10,
          (index) => _imagePost(id: 'im${index + 1}'),
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
      final kinds = result.map(_startupKindForPost).toList(growable: false);

      expect(result, hasLength(30));
      expect(kinds[5], 'flood');
      expect(kinds[15], 'flood');
      expect(kinds[25], 'flood');
      expect(kinds.where((kind) => kind == 'flood').length, 3);
      expect(kinds.sublist(0, 10).where((kind) => kind == 'flood').length, 1);
      expect(kinds.sublist(10, 20).where((kind) => kind == 'flood').length, 1);
      expect(kinds.sublist(20, 30).where((kind) => kind == 'flood').length, 1);
    });

    test(
        'composeStartupFeedItems widens image and text buckets without allowing extra flood drift',
        () {
      final service = AgendaFeedApplicationService();

      final liveCandidates = List<PostsModel>.generate(
        30,
        (index) => _readyVideoPost(id: 'lv${index + 1}'),
      );
      final cacheCandidates = <PostsModel>[
        ...List<PostsModel>.generate(
          12,
          (index) => _readyVideoPost(id: 'cv${index + 1}'),
        ),
        _imageTextPost(id: 'mix1'),
        _imageTextPost(id: 'mix2'),
        _imageTextPost(id: 'mix3'),
        _imageTextPost(id: 'mix4'),
        _imageTextPost(id: 'mix5'),
        _imageTextPost(id: 'mix6'),
        ...List<PostsModel>.generate(
          6,
          (index) => _floodPost(id: 'fl${index + 1}'),
        ),
      ];

      final result = service.composeStartupFeedItems(
        liveCandidates: liveCandidates,
        cacheCandidates: cacheCandidates,
        targetCount: 30,
      );
      final kinds = result.map(_startupKindForPost).toList(growable: false);

      expect(result, hasLength(30));
      expect(kinds[2], 'image');
      expect(result[8].docID, startsWith('mix'));
      expect(kinds[12], 'image');
      expect(result[18].docID, startsWith('mix'));
      expect(kinds.where((kind) => kind == 'flood').length, 3);
    });

    test(
        'composeStartupFeedItems can fill sparse late blocks without collapsing to one item',
        () {
      final service = AgendaFeedApplicationService();

      final cacheCandidates = <PostsModel>[
        _readyVideoPost(id: 'cv1'),
        ...List<PostsModel>.generate(
          18,
          (index) => _imagePost(id: 'im${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          6,
          (index) => _floodPost(id: 'fl${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          12,
          (index) => _textPost(id: 'tx${index + 1}'),
        ),
      ];

      final result = service.composeStartupFeedItems(
        liveCandidates: const <PostsModel>[],
        cacheCandidates: cacheCandidates,
        targetCount: 30,
        allowSparseSlotFallback: true,
      );
      final kinds = result.map(_startupKindForPost).toList(growable: false);

      expect(result, hasLength(30));
      expect(kinds.first, 'cache');
      expect(
          kinds.where((kind) => kind == 'flood').length, lessThanOrEqualTo(3));
      expect(kinds.sublist(0, 10).where((kind) => kind == 'flood').length,
          lessThanOrEqualTo(1));
      expect(kinds.sublist(10, 20).where((kind) => kind == 'flood').length,
          lessThanOrEqualTo(1));
      expect(kinds.sublist(20, 30).where((kind) => kind == 'flood').length,
          lessThanOrEqualTo(1));
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

    test('resolveNextBufferedFetchTrigger advances in ten-card strides', () {
      final service = AgendaFeedApplicationService();

      expect(
        service.resolveNextBufferedFetchTrigger(
          currentTrigger: 10,
          viewedCount: 10,
          stride: 10,
        ),
        20,
      );
      expect(
        service.resolveNextBufferedFetchTrigger(
          currentTrigger: 20,
          viewedCount: 20,
          stride: 10,
        ),
        30,
      );
      expect(
        service.resolveNextBufferedFetchTrigger(
          currentTrigger: 30,
          viewedCount: 30,
          stride: 10,
        ),
        40,
      );
      expect(
        service.resolveNextBufferedFetchTrigger(
          currentTrigger: 10,
          viewedCount: 27,
          stride: 10,
        ),
        30,
      );
    });

    test('resolveBufferedWindowPlan locks thirty-card blocks in ten-card steps',
        () {
      final service = AgendaFeedApplicationService();

      final planAt10 = service.resolveBufferedWindowPlan(
        viewedCount: 10,
        initialCount: 30,
        blockSize: 30,
        stepSize: 10,
      );
      expect(planAt10, isNotNull);
      expect(planAt10!.blockBaseCount, 30);
      expect(planAt10.targetAgendaCount, 40);
      expect(planAt10.startsNewBlock, isTrue);

      final planAt20 = service.resolveBufferedWindowPlan(
        viewedCount: 20,
        initialCount: 30,
        blockSize: 30,
        stepSize: 10,
      );
      expect(planAt20, isNotNull);
      expect(planAt20!.blockBaseCount, 30);
      expect(planAt20.targetAgendaCount, 50);
      expect(planAt20.startsNewBlock, isFalse);

      final planAt30 = service.resolveBufferedWindowPlan(
        viewedCount: 30,
        initialCount: 30,
        blockSize: 30,
        stepSize: 10,
      );
      expect(planAt30, isNotNull);
      expect(planAt30!.blockBaseCount, 30);
      expect(planAt30.targetAgendaCount, 60);
      expect(planAt30.startsNewBlock, isFalse);

      final planAt40 = service.resolveBufferedWindowPlan(
        viewedCount: 40,
        initialCount: 30,
        blockSize: 30,
        stepSize: 10,
      );
      expect(planAt40, isNotNull);
      expect(planAt40!.blockBaseCount, 60);
      expect(planAt40.targetAgendaCount, 70);
      expect(planAt40.startsNewBlock, isTrue);

      final planAt70 = service.resolveBufferedWindowPlan(
        viewedCount: 70,
        initialCount: 30,
        blockSize: 30,
        stepSize: 10,
      );
      expect(planAt70, isNotNull);
      expect(planAt70!.blockBaseCount, 90);
      expect(planAt70.targetAgendaCount, 100);
      expect(planAt70.startsNewBlock, isTrue);

      final planAt100 = service.resolveBufferedWindowPlan(
        viewedCount: 100,
        initialCount: 30,
        blockSize: 30,
        stepSize: 10,
      );
      expect(planAt100, isNotNull);
      expect(planAt100!.blockBaseCount, 120);
      expect(planAt100.targetAgendaCount, 130);
      expect(planAt100.startsNewBlock, isTrue);
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
        'mergeStartupHeadWithCurrentItems keeps flood-complete startup head when live-only head is weaker',
        () {
      final service = AgendaFeedApplicationService();
      final nowMs = DateTime(2026, 4, 7, 0, 30).millisecondsSinceEpoch;

      final currentItems = <PostsModel>[
        ...List<PostsModel>.generate(
          12,
          (index) => _readyVideoPost(id: 'cv${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          12,
          (index) => _imagePost(id: 'im${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          8,
          (index) => _floodPost(id: 'fl${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          4,
          (index) => _textPost(id: 'tx${index + 1}'),
        ),
      ];
      final liveItems = <PostsModel>[
        ...List<PostsModel>.generate(
          24,
          (index) => _readyVideoPost(id: 'lv${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          6,
          (index) => _imagePost(id: 'lim${index + 1}'),
        ),
      ];

      final merged = service.mergeStartupHeadWithCurrentItems(
        currentItems: currentItems,
        liveItems: liveItems,
        targetCount: 30,
        nowMs: nowMs,
        preferLiveStartupHead: true,
      );

      expect(
        merged.take(30).map(_startupKindForPost).toList(growable: false),
        const <String>[
          'cache',
          'cache',
          'image',
          'live',
          'live',
          'flood',
          'cache',
          'cache',
          'text',
          'live',
          'cache',
          'cache',
          'image',
          'live',
          'live',
          'flood',
          'cache',
          'cache',
          'text',
          'live',
          'cache',
          'cache',
          'image',
          'live',
          'live',
          'flood',
          'cache',
          'cache',
          'text',
          'live',
        ],
      );
      expect(
        merged
            .take(30)
            .where((post) => _startupKindForPost(post) == 'flood')
            .length,
        3,
      );
    });

    test(
        'shouldPreferLiveStartupHeadForMerge rejects incomplete live-only heads',
        () {
      final service = AgendaFeedApplicationService();

      final currentItems = <PostsModel>[
        ...List<PostsModel>.generate(
          12,
          (index) => _readyVideoPost(id: 'cv${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          12,
          (index) => _imagePost(id: 'im${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          8,
          (index) => _floodPost(id: 'fl${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          4,
          (index) => _textPost(id: 'tx${index + 1}'),
        ),
      ];
      final liveItems = <PostsModel>[
        ...List<PostsModel>.generate(
          10,
          (index) => _readyVideoPost(id: 'lv${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          3,
          (index) => _imagePost(id: 'lim${index + 1}'),
        ),
        ...List<PostsModel>.generate(
          4,
          (index) => _floodPost(id: 'lfl${index + 1}'),
        ),
      ];

      expect(
        service.shouldPreferLiveStartupHeadForMerge(
          currentItems: currentItems,
          liveItems: liveItems,
          targetCount: 30,
        ),
        isFalse,
      );
    });

    test(
        'startup support path keeps flood roots outside the normal time window',
        () {
      final loadingCacheSource = File(
        '/Users/turqapp/Documents/Turqapp/repo/lib/Modules/Agenda/agenda_controller_loading_cache_part.dart',
      ).readAsStringSync();
      final repositorySource = File(
        '/Users/turqapp/Documents/Turqapp/repo/lib/Core/Repositories/post_repository_query_part.dart',
      ).readAsStringSync();

      expect(
        loadingCacheSource,
        contains(
            "if (kind == 'flood') {\n        primaryCandidates.add(post);"),
      );
      expect(
        loadingCacheSource,
        contains('_postRepository.fetchFloodSeriesRoots('),
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
  });
}

void _expectLockedTenSlotMotif(List<PostsModel> posts) {
  expect(posts.length % 10, 0);
  for (var start = 0; start < posts.length; start += 10) {
    final chunk = posts.sublist(start, start + 10);
    final chunkKinds = chunk.map(_startupKindForPost).toList(growable: false);
    expect(
      chunkKinds.where((kind) => kind == 'flood').length,
      1,
      reason: 'chunk ${start ~/ 10} flood count',
    );
    expect(
      chunkKinds[2],
      'image',
      reason: 'chunk ${start ~/ 10} image slot',
    );
    expect(
      chunkKinds[5],
      'flood',
      reason: 'chunk ${start ~/ 10} flood slot',
    );
    for (final index in <int>[0, 1, 3, 4, 6, 7, 8, 9]) {
      expect(
        <String>['cache', 'live'].contains(chunkKinds[index]),
        isTrue,
        reason: 'chunk ${start ~/ 10} video slot ${index + 1}',
      );
    }
  }
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

PostsModel _imageTextPost({
  required String id,
  int timeStamp = 0,
}) {
  return _post(id: id, timeStamp: timeStamp)
    ..img = <String>['https://cdn.example.com/$id.jpg']
    ..metin = 'text-$id';
}

PostsModel _floodPost({
  required String id,
  int timeStamp = 0,
}) {
  return _post(id: id, timeStamp: timeStamp)
    ..floodCount = 3
    ..thumbnail = 'https://cdn.example.com/$id-thumb.jpg';
}

PostsModel _floodMemberVideoPost({
  required String id,
  int timeStamp = 0,
}) {
  return _readyVideoPost(id: id, timeStamp: timeStamp)
    ..flood = true
    ..mainFlood = 'series-$id';
}

String _startupKindForPost(PostsModel post) {
  if (post.isFloodSeriesContent) return 'flood';
  if (post.hasPlayableVideo) {
    return post.docID.startsWith('lv') ? 'live' : 'cache';
  }
  if (!post.hasVideoSignal && post.hasImageContent) return 'image';
  if (!post.hasVideoSignal && !post.hasImageContent && post.hasTextContent) {
    return 'text';
  }
  return 'other';
}
