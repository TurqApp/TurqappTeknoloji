import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Repositories/feed_home_contract.dart';
import 'package:turqappv2/Core/Repositories/feed_snapshot_repository.dart';

void main() {
  group('FeedHomeContract', () {
    test('defines the canonical primary home feed path', () {
      const contract = FeedHomeContract.primaryHybridV1;

      expect(contract.contractId, 'feed_home_primary_global_v2');
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
        const <FeedHomeFallbackPath>[
          FeedHomeFallbackPath.personalSnapshot,
          FeedHomeFallbackPath.legacyPage,
        ],
      );
      expect(contract.usesPrimaryFeedPaging, isFalse);
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

    test('repository remains manifest-first with warm and personal fallbacks',
        () {
      final fetchSource = File(
        '/Users/turqapp/Documents/Turqapp/repo/lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart',
      ).readAsStringSync();

      expect(fetchSource, contains('_tryLoadFeedManifestPrimaryPage('));
      expect(fetchSource, contains('_loadWarmFeedFallbackPage('));
      expect(fetchSource, contains('_loadPersonalFallbackPage('));
      expect(fetchSource, contains("status=fallback_warm"));
      expect(fetchSource, contains("status=fallback_personal"));
    });

    test('explicit opt-out is manifest-only and legacy page is unreachable', 
        () {
      final fetchSource = File(
        '/Users/turqapp/Documents/Turqapp/repo/lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart',
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

    test('manifest page windows preserve startup head then continue in blocks',
        () {
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
      expect(first.pageEndExclusive, 15);
      expect(first.deckLimit, 15);

      expect(second.pageStart, 15);
      expect(second.pageEndExclusive, 39);
      expect(second.deckLimit, 39);

      expect(third.pageStart, 39);
      expect(third.pageEndExclusive, 63);
      expect(third.deckLimit, 63);
    });

    test('manifest selection does not bypass consumed newest-slot cards', () {
      final fetchSource = File(
        '/Users/turqapp/Documents/Turqapp/repo/lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart',
      ).readAsStringSync();

      expect(fetchSource, contains('if (consumedDocIds.contains(docId)) {'));
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
        '/Users/turqapp/Documents/Turqapp/repo/lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart',
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
        contains(
          'slotOrder.sort(FeedManifestMixer.compareSlotKeysNewestFirst);',
        ),
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
        contains('visible.skip(pageStart).take(limit).toList'),
      );
      expect(
        fetchSource,
        contains('visibleEntries.skip(pageStart).take(limit).toList'),
      );
    });

    test(
        'startup feed does not auto-append planned cold pages without explicit near-end triggers',
        () {
      final loadingSource = File(
        '/Users/turqapp/Documents/Turqapp/repo/lib/Modules/Agenda/agenda_controller_loading_part.dart',
      ).readAsStringSync();

      expect(
        loadingSource,
        contains('final shouldDeferPlannedColdConsumption = usesPlannedColdPage'),
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
    });
  });
}
