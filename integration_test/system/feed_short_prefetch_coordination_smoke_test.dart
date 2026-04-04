import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/SegmentCache/cache_manager.dart';
import 'package:turqappv2/Core/Services/SegmentCache/prefetch_scheduler.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/short_surface_mix_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Modules/Agenda/agenda_controller.dart';
import 'package:turqappv2/Modules/Short/short_controller.dart';

import '../core/bootstrap/test_app_bootstrap.dart';
import '../core/helpers/smoke_artifact_collector.dart';
import '../core/helpers/test_state_probe.dart';

void main() {
  ensureIntegrationBinding();

  testWidgets(
    'Feed, short, bank, queue and cache stay coordinated on startup',
    (tester) async {
      await SmokeArtifactCollector.runScenario(
        'feed_short_prefetch_coordination',
        tester,
        () async {
          await launchTurqApp(
            tester,
            relaxFeedFixtureDocRequirement: true,
            primeShortSnapshot: true,
          );
          expect(byItKey(IntegrationTestKeys.screenFeed), findsOneWidget);
          expectSurfaceRegistered('feed');

          final feedSnapshot = await _waitForFeedPrefetchSnapshot(tester);
          _expectFeedBankPhaseLooksHealthy(feedSnapshot);

          await tapItKey(tester, IntegrationTestKeys.navShort, settlePumps: 12);
          expect(byItKey(IntegrationTestKeys.screenShort), findsOneWidget);
          expectSurfaceRegistered('short');

          final shortController = await _waitForShortSurface(tester);
          await _waitForShortSurfaceToExcludeCurrentFeedVideos(
            tester,
            feedDocIds: feedSnapshot.surfaceFeedVideoDocIds,
            controller: shortController,
          );

          await _expectShortRankingUsesCacheAndQueueSignals(
            tester,
            controller: shortController,
          );
        },
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
    skip: !kRunIntegrationSmoke,
  );
}

class _FeedPrefetchSnapshot {
  const _FeedPrefetchSnapshot({
    required this.surfaceFeedVideoDocIds,
    required this.feedDocIds,
    required this.bankDocIds,
    required this.bankQueued,
  });

  final List<String> surfaceFeedVideoDocIds;
  final List<String> feedDocIds;
  final List<String> bankDocIds;
  final bool bankQueued;
}

Future<_FeedPrefetchSnapshot> _waitForFeedPrefetchSnapshot(
  WidgetTester tester,
) async {
  final controller = ensureAgendaController();
  final scheduler = ensurePrefetchScheduler();
  final cacheManager = ensureSegmentCacheManager();
  if (!cacheManager.isReady) {
    await cacheManager.init();
  }

  final surfaceFeedVideoDocIds = controller.agendaList
      .where((post) => post.hasPlayableVideo)
      .map((post) => post.docID.trim())
      .where((docId) => docId.isNotEmpty)
      .take(24)
      .toList(growable: false);
  expect(
    surfaceFeedVideoDocIds,
    isNotEmpty,
    reason: 'feed surface has no playable video candidates',
  );

  final syntheticSchedulerPosts = _buildSyntheticEligibleFeedPrefetchPosts(
    controller.agendaList.where((post) => post.hasPlayableVideo).toList(),
  );
  expect(
    syntheticSchedulerPosts.length,
    greaterThanOrEqualTo(12),
    reason:
        'not enough feed video seeds for deterministic prefetch smoke phase',
  );

  await scheduler.updateFeedQueueForPosts(syntheticSchedulerPosts, 0);

  for (var attempt = 0; attempt < 48; attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
    final feedDocIds = scheduler
        .currentFeedDocIds()
        .map((docId) => docId.trim())
        .where((docId) => docId.isNotEmpty)
        .toList(growable: false);
    final bankDocIds = scheduler
        .currentFeedBankDocIds()
        .map((docId) => docId.trim())
        .where((docId) => docId.isNotEmpty)
        .toList(growable: false);
    final bankQueued = bankDocIds.any(
      (docId) =>
          scheduler.queuePositionForDoc(docId) >= 0 ||
          scheduler.hasPendingPrefetchForDoc(docId) ||
          scheduler.isActivelyDownloadingDoc(docId),
    );
    if (feedDocIds.isNotEmpty && bankDocIds.isNotEmpty && bankQueued) {
      await expectNoFlutterException(tester);
      return _FeedPrefetchSnapshot(
        surfaceFeedVideoDocIds: surfaceFeedVideoDocIds,
        feedDocIds: feedDocIds,
        bankDocIds: bankDocIds,
        bankQueued: bankQueued,
      );
    }
  }

  final playableFeedCount =
      controller.agendaList.where((post) => post.hasPlayableVideo).length;
  throw TestFailure(
    'feed prefetch state did not stabilize '
    '(playableFeedCount=$playableFeedCount, '
    'surfaceFeedVideoCount=${surfaceFeedVideoDocIds.length}, '
    'feedDocIds=${scheduler.currentFeedDocIds().length}, '
    'bankDocIds=${scheduler.currentFeedBankDocIds().length}, '
    'queueSize=${scheduler.queueSize}, '
    'activeDownloads=${scheduler.activeDownloads}).',
  );
}

void _expectFeedBankPhaseLooksHealthy(_FeedPrefetchSnapshot snapshot) {
  expect(snapshot.feedDocIds, isNotEmpty, reason: 'feed queue doc ids empty');
  expect(snapshot.bankDocIds, isNotEmpty, reason: 'feed bank doc ids empty');
  expect(snapshot.bankQueued, isTrue,
      reason: 'feed bank batch never reached the active prefetch queue');
}

Future<ShortController> _waitForShortSurface(WidgetTester tester) async {
  final controller = ensureShortController();
  await controller.prepareStartupSurface(allowBackgroundRefresh: false);

  for (var attempt = 0; attempt < 40; attempt++) {
    await tester.pump(const Duration(milliseconds: 250));
    final payload = maybeReadSurfaceProbe('short');
    final count =
        (payload?['count'] as num?)?.toInt() ?? controller.shorts.length;
    if (count >= 4 && controller.shorts.length >= 4) {
      await expectNoFlutterException(tester);
      return controller;
    }
  }

  throw TestFailure(
    'short surface did not populate enough items '
    '(count=${controller.shorts.length}).',
  );
}

Future<void> _waitForShortSurfaceToExcludeCurrentFeedVideos(
  WidgetTester tester, {
  required List<String> feedDocIds,
  required ShortController controller,
}) async {
  final feedDocIdSet = feedDocIds
      .map((docId) => docId.trim())
      .where((docId) => docId.isNotEmpty)
      .toSet();
  Set<String> lastVisibleOverlap = const <String>{};

  for (var attempt = 0; attempt < 32; attempt++) {
    await controller.reconcileVisibleShortSurface(
      trigger: 'integration_short_feed_conflict_wait',
    );
    await tester.pump(const Duration(milliseconds: 250));
    final visibleShortDocIds = controller.shorts
        .take(18)
        .map((post) => post.docID.trim())
        .where((docId) => docId.isNotEmpty)
        .toSet();
    expect(visibleShortDocIds, isNotEmpty, reason: 'short list is empty');

    lastVisibleOverlap = visibleShortDocIds.intersection(feedDocIdSet);
    final hasAnyNonConflictShort = controller.shorts.any(
      (post) => !feedDocIdSet.contains(post.docID.trim()),
    );
    if (!hasAnyNonConflictShort || lastVisibleOverlap.isEmpty) {
      await expectNoFlutterException(tester);
      return;
    }
  }

  expect(
    lastVisibleOverlap,
    isEmpty,
    reason:
        'feed-visible video doc ids leaked into short surface despite non-conflict short candidates: ${lastVisibleOverlap.toList()}',
  );
}

List<PostsModel> _buildSyntheticEligibleFeedPrefetchPosts(
  List<PostsModel> playableFeedPosts,
) {
  final seeds = playableFeedPosts
      .where((post) => post.docID.trim().isNotEmpty)
      .take(28)
      .toList(growable: false);
  return seeds
      .map(
        (seed) => seed.copyWith(
          rozet: seed.rozet.trim().isEmpty ? 'mavi' : seed.rozet,
        ),
      )
      .toList(growable: false);
}

Future<void> _expectShortRankingUsesCacheAndQueueSignals(
  WidgetTester tester, {
  required ShortController controller,
}) async {
  final cacheManager = ensureSegmentCacheManager();
  if (!cacheManager.isReady) {
    await cacheManager.init();
  }
  final scheduler = ensurePrefetchScheduler();

  final seeds = controller.shorts
      .where((post) => post.hasPlayableVideo && post.rozet.trim().isNotEmpty)
      .take(4)
      .toList(growable: false);
  expect(
    seeds.length,
    greaterThanOrEqualTo(4),
    reason: 'not enough short seeds for ranking smoke phase',
  );

  final scenarioPosts = <PostsModel>[
    _cloneShortForSignalSmoke(seeds[0], 'queued'),
    _cloneShortForSignalSmoke(seeds[1], 'cached'),
    _cloneShortForSignalSmoke(seeds[2], 'plain_a'),
    _cloneShortForSignalSmoke(seeds[3], 'plain_b'),
  ];
  cacheManager.cachePostCards(scenarioPosts);

  cacheManager.updateWatchProgress(scenarioPosts[0].docID, 0.0);
  cacheManager.updateWatchProgress(scenarioPosts[1].docID, 0.25);
  cacheManager.updateWatchProgress(scenarioPosts[2].docID, 0.92);
  expect(resolveShortMixBucket(scenarioPosts[0]), ShortMixBucket.fresh);
  expect(resolveShortMixBucket(scenarioPosts[1]), ShortMixBucket.warm);
  expect(resolveShortMixBucket(scenarioPosts[2]), ShortMixBucket.rescue);

  for (final post in scenarioPosts) {
    cacheManager.updateWatchProgress(post.docID, 0.25);
  }

  final queuedDoc = scenarioPosts[0];
  final cachedDoc = scenarioPosts[1];
  cacheManager.updateEntryMeta(cachedDoc.docID, cachedDoc.playbackUrl, 4);
  await cacheManager.writeSegment(
    cachedDoc.docID,
    'smoke/segment_0.ts',
    Uint8List.fromList(List<int>.filled(16, 7)),
  );
  await cacheManager.writeSegment(
    cachedDoc.docID,
    'smoke/segment_1.ts',
    Uint8List.fromList(List<int>.filled(16, 9)),
  );

  scheduler.pause();
  await scheduler.updateQueueForPosts(
    <PostsModel>[queuedDoc],
    0,
    maxDocs: 1,
  );
  final queuedShortIsTracked =
      scheduler.queuePositionForDoc(queuedDoc.docID) >= 0 ||
          scheduler.hasPendingPrefetchForDoc(queuedDoc.docID) ||
          scheduler.isActivelyDownloadingDoc(queuedDoc.docID);

  final mixed = mixShortPresentationPosts(
    <PostsModel>[
      scenarioPosts[2],
      queuedDoc,
      scenarioPosts[3],
      cachedDoc,
    ],
    sessionNamespace: 'integration_short_prefetch_coordination',
  );
  final topTwoDocIds = mixed.take(2).map((post) => post.docID).toSet();
  final expectedTopTwoDocIds = <String>{cachedDoc.docID};
  if (queuedShortIsTracked) {
    expectedTopTwoDocIds.add(queuedDoc.docID);
  }
  expect(
    topTwoDocIds,
    containsAll(expectedTopTwoDocIds),
    reason:
        'cache/queue signals did not bubble prepared short candidates to the head',
  );

  scheduler.resume();
  await tester.pump(const Duration(milliseconds: 250));
  await expectNoFlutterException(tester);
}

PostsModel _cloneShortForSignalSmoke(PostsModel seed, String label) {
  return seed.copyWith(
    docID: 'it_short_prefetch_${label}_${seed.docID}',
    shortId: 'it_short_prefetch_${label}_${seed.shortId}',
  );
}
