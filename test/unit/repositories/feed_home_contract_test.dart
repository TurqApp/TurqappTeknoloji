import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Repositories/feed_home_contract.dart';

void main() {
  group('FeedHomeContract', () {
    test('defines the canonical primary home feed path', () {
      const contract = FeedHomeContract.primaryHybridV1;

      expect(contract.contractId, 'feed_home_primary_hybrid_v1');
      expect(
        contract.primarySource,
        FeedHomePrimarySource.userFeedReferences,
      );
      expect(
        contract.supplementalSources,
        const <FeedHomeSupplementalSource>[
          FeedHomeSupplementalSource.ownRecentPosts,
          FeedHomeSupplementalSource.celebrityRecentPosts,
          FeedHomeSupplementalSource.publicScheduledIzBirakPosts,
          FeedHomeSupplementalSource.globalBadgePosts,
        ],
      );
      expect(
        contract.fallbackOrder,
        const <FeedHomeFallbackPath>[
          FeedHomeFallbackPath.personalSnapshot,
          FeedHomeFallbackPath.legacyPage,
        ],
      );
      expect(contract.usesPrimaryFeedPaging, isTrue);
      expect(contract.primaryCollection, 'userFeeds');
      expect(contract.primaryItemsSubcollection, 'items');
      expect(contract.celebrityCollection, 'celebAccounts');
      expect(
        contract.requiredReferenceFields,
        const <String>[
          'postId',
          'authorId',
          'timeStamp',
          'isCelebrity',
          'expiresAt',
        ],
      );
    });

    test('repository is bound to the canonical home feed contract', () {
      final repositorySource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/feed_snapshot_repository_class_part.dart',
      ).readAsStringSync();
      final fetchSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart',
      ).readAsStringSync();

      expect(
        repositorySource,
        contains('FeedHomeContract.primaryHybridV1'),
      );
      expect(
        fetchSource,
        contains("feedContract': contract.contractId"),
      );
    });

    test('repository fallback order preserves personal feed before legacy page',
        () {
      final fetchSource = File(
        '/Users/turqapp/Desktop/TurqApp/lib/Core/Repositories/feed_snapshot_repository_fetch_part.dart',
      ).readAsStringSync();

      final personalPrimaryEmpty =
          fetchSource.indexOf('fallback=personal reason=primary_empty');
      final legacyPersonalEmpty =
          fetchSource.indexOf('fallback=legacy reason=personal_empty');
      final personalVisibleEmpty = fetchSource.indexOf('fallback=personal \'');
      final legacyVisibleEmpty = fetchSource.indexOf('fallback=legacy \'');

      expect(personalPrimaryEmpty, greaterThanOrEqualTo(0));
      expect(legacyPersonalEmpty, greaterThan(personalPrimaryEmpty));
      expect(personalVisibleEmpty, greaterThanOrEqualTo(0));
      expect(legacyVisibleEmpty, greaterThan(personalVisibleEmpty));
      expect(
          fetchSource,
          contains(
              'final personalFallback = await _loadPersonalFallbackPage('));
      expect(fetchSource, contains('return _loadLegacyPage('));
    });
  });
}
