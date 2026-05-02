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
  });
}
