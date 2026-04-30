import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Repositories/feed_home_contract.dart';

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
        contains('if (!usePrimaryFeedPaging || normalizedUserId.isEmpty) {'),
      );
      expect(
        fetchSource,
        contains(
          "return const FeedSourcePage(\n        items: <PostsModel>[],",
        ),
      );
      expect(fetchSource, isNot(contains('_loadLegacyPage(')));
    });
  });
}
