import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Repositories/feed_home_contract.dart';
import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';

void main() {
  group('FeedHomeContract', () {
    test('defines the canonical primary home feed path', () {
      const contract = FeedHomeContract.primaryHybridV1;

      expect(contract.contractId, 'feed_home_manifest_only_v1');
      expect(
        contract.primarySource,
        FeedHomePrimarySource.globalApprovedPosts,
      );
      expect(
        contract.supplementalSources,
        const <FeedHomeSupplementalSource>[
          FeedHomeSupplementalSource.ownRecentPosts,
          FeedHomeSupplementalSource.publicScheduledIzBirakPosts,
        ],
      );
      expect(
        contract.fallbackOrder,
        const <FeedHomeFallbackPath>[],
      );
      expect(contract.usesPrimaryFeedPaging, isTrue);
      expect(contract.primaryCollection, 'Posts');
      expect(contract.primaryItemsSubcollection, isEmpty);
      expect(contract.celebrityCollection, 'celebAccounts');
      expect(
        contract.requiredReferenceFields,
        const <String>[
          'timeStamp',
          'userID',
        ],
      );
    });

    test('repository remains manifest-only without cache fallbacks', () {
      final fetchSource = File(
        'lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart',
      ).readAsStringSync();

      expect(fetchSource, contains('_tryLoadFeedManifestPrimaryPage('));
      expect(fetchSource, isNot(contains('_loadWarmFeedFallbackPage(')));
      expect(fetchSource, isNot(contains('_loadPersonalFallbackPage(')));
      expect(fetchSource, isNot(contains("status=fallback_warm")));
      expect(fetchSource, isNot(contains("status=fallback_personal")));
      expect(fetchSource, contains("status=manifest_only_no_fallback"));
    });

    test('explicit opt-out is manifest-only and legacy page is unreachable',
        () {
      final fetchSource = File(
        'lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart',
      ).readAsStringSync();

      expect(
        fetchSource,
        contains('if (!usePrimaryFeedPaging) {'),
      );
      expect(
        fetchSource,
        contains(
          "return const FeedSourcePage(\n        items: <PostsModel>[],",
        ),
      );
      expect(fetchSource, isNot(contains('_loadLegacyPage(')));
    });

    test('manifest page windows cap startup head then continue in blocks', () {
      final first = FeedSnapshotRepository.resolveManifestPageWindow(
        pageNumber: 1,
        pageSize: 15,
      );
      final second = FeedSnapshotRepository.resolveManifestPageWindow(
        pageNumber: 2,
        pageSize: 24,
      );
      final third = FeedSnapshotRepository.resolveManifestPageWindow(
        pageNumber: 3,
        pageSize: 24,
      );

      expect(first.pageStart, 0);
      expect(first.pageEndExclusive, 135);
      expect(first.deckLimit, 135);

      expect(second.pageStart, 135);
      expect(second.pageEndExclusive, 159);
      expect(second.deckLimit, 159);

      expect(third.pageStart, 159);
      expect(third.pageEndExclusive, 183);
      expect(third.deckLimit, 183);
    });

    test('manifest selection prunes watched cards and bypasses empty slots',
        () {
      final fetchSource = File(
        'lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart',
      ).readAsStringSync();

      expect(fetchSource, contains('if (consumedDocIds.contains(docId)) {'));
      expect(
        fetchSource,
        contains(
          'final consumedDocIds = _feedDiversityMemory.weeklyWatchedPenaltyDocIds();',
        ),
      );
      expect(
        fetchSource,
        contains(
          'final consumedFloodRootIds =\n          _feedDiversityMemory.weeklyWatchedFloodRootIds();',
        ),
      );
      expect(fetchSource, contains('consumedDocIds: consumedDocIds'));
      expect(
        fetchSource,
        contains('consumedFloodRootIds: consumedFloodRootIds'),
      );
      expect(
        fetchSource,
        contains('if (_isNonRootFloodChildPost(post)) return;'),
      );
      expect(
        fetchSource,
        contains('if (floodRootId.isNotEmpty &&'),
      );
      expect(
        fetchSource,
        contains('consumedFloodRootIds.contains(floodRootId)'),
      );
      expect(fetchSource, contains('status=slot_exhausted_bypass'));
      expect(
        fetchSource,
        isNot(contains('status=newest_slot_grace')),
      );
      expect(
        fetchSource,
        isNot(contains('keptDocs=')),
      );
    });

    test(
        'manifest visible selection stays gap-first then newest-to-oldest in five-card slot batches',
        () {
      final fetchSource = File(
        'lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart',
      ).readAsStringSync();

      expect(
        fetchSource,
        contains('for (final entry in gapEntries) {'),
      );
      expect(
        fetchSource,
        contains('for (final entry in manifestEntries) {'),
      );
      expect(
        fetchSource,
        contains('slotOrder.sort((left, right) {'),
      );
      expect(
        fetchSource,
        contains('FeedManifestMixer.compareEntriesBySlotNewestFirst('),
      );
      expect(
        fetchSource,
        contains(
          'selected.addAll(gapBucket.take(takeCount));',
        ),
      );
      expect(
        fetchSource,
        contains('FeedManifestPolicy.gapSlotBatchSize'),
      );
      expect(
        fetchSource,
        contains('selected.addAll(bucket.take(takeCount));'),
      );
      expect(
        fetchSource,
        contains('FeedManifestMixer.defaultSlotBatchSize'),
      );
      expect(
        fetchSource,
        contains("if (post.mainFlood.trim().isNotEmpty) return true;"),
      );
      expect(
        fetchSource,
        contains('if (post.flood == true && !post.isFloodSeriesRoot)'),
      );
      expect(
        fetchSource,
        contains(
          'effectiveNowMs - FeedManifestPolicy.gapWindowDuration.inMilliseconds',
        ),
      );
      expect(
        fetchSource,
        contains('final pageTakeLimit = max(0, pageEndExclusive - pageStart);'),
      );
      expect(
        fetchSource,
        contains('visible.skip(pageStart).take(pageTakeLimit).toList'),
      );
      expect(
        fetchSource,
        contains('.take(pageTakeLimit)'),
      );
      expect(
        fetchSource,
        contains(
          'final nextPage =\n          visible.length > pageEndExclusive ? pageNumber + 1 : null;',
        ),
      );
      expect(fetchSource, isNot(contains('_feedManifestMixer.buildDeck(')));
    });

    test(
        'startup feed does not auto-append planned cold pages without explicit near-end triggers',
        () {
      final loadingSource = File(
        'lib/Modules/Agenda/agenda_controller_loading_part.dart',
      ).readAsStringSync();

      expect(
        loadingSource,
        contains(
            'final shouldDeferPlannedColdConsumption = usesPlannedColdPage'),
      );
      expect(
        loadingSource,
        contains("trigger != 'scroll_near_end'"),
      );
      expect(
        loadingSource,
        contains("trigger != 'promo_near_end'"),
      );
      expect(
        loadingSource,
        contains('[FeedAppendDiagnostics] status=skip_auto_planned_cold_apply'),
      );
      expect(
        loadingSource,
        contains('status=skip_preplanned_append_terminal'),
      );
      expect(
        loadingSource,
        contains(
            'effectivePageItemsPreplanned\n          ? page.nextTypesensePage != null'),
      );
      expect(
        loadingSource,
        contains(
            'pageApplyPlan.pageItemsPreplanned\n          ? page.nextTypesensePage != null'),
      );
    });

    test('manifest refresh skips current-list pre-prune flicker', () {
      final loadingSource = File(
        'lib/Modules/Agenda/agenda_controller_loading_part.dart',
      ).readAsStringSync();

      expect(
        loadingSource,
        contains('skipPrePruneForManifestRefresh'),
      );
      expect(
        loadingSource,
        contains('_usePrimaryFeedPaging && !isFollowingMode && !isCityMode'),
      );
      expect(
        loadingSource,
        contains('status=skip_pre_prune_manifest_refresh'),
      );
      expect(
        loadingSource,
        contains("String reason = 'refresh_merge_live_items'"),
      );
      expect(
        loadingSource,
        contains("reason: 'refresh_prune_consumed_current'"),
      );
    });
  });
}
