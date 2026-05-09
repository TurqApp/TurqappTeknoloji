import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/feed_manifest_policy.dart';

void main() {
  group('FeedManifestPolicy', () {
    test('enables manifest primary by default in debug-mode builds', () {
      expect(FeedManifestPolicy.primaryEnabled, isTrue);
    });

    test('deck seed changes by user, manifest, and startup session', () {
      final base = FeedManifestPolicy.resolveDeckSeed(
        userId: 'u1',
        manifestId: 'm1',
        startupSeed: 10,
      );

      expect(
        FeedManifestPolicy.resolveDeckSeed(
          userId: 'u2',
          manifestId: 'm1',
          startupSeed: 10,
        ),
        isNot(base),
      );
      expect(
        FeedManifestPolicy.resolveDeckSeed(
          userId: 'u1',
          manifestId: 'm2',
          startupSeed: 10,
        ),
        isNot(base),
      );
      expect(
        FeedManifestPolicy.resolveDeckSeed(
          userId: 'u1',
          manifestId: 'm1',
          startupSeed: 11,
        ),
        isNot(base),
      );
    });

    test('gap candidate limit stays bounded', () {
      expect(
        FeedManifestPolicy.resolveGapCandidateLimit(10),
        FeedManifestPolicy.minGapCandidateLimit,
      );
      expect(
        FeedManifestPolicy.resolveGapCandidateLimit(40),
        FeedManifestPolicy.minGapCandidateLimit,
      );
      expect(
        FeedManifestPolicy.resolveGapCandidateLimit(120),
        FeedManifestPolicy.maxGapCandidateLimit,
      );
      expect(
        FeedManifestPolicy.resolveGapCandidateLimit(999),
        FeedManifestPolicy.maxGapCandidateLimit,
      );
    });

    test('does not impose author-spacing caps in runtime deck policy', () {
      expect(FeedManifestPolicy.minUserSpacing, 0);
      expect(FeedManifestPolicy.maxItemsPerUser, greaterThan(1000));
    });

    test('startup slot load budget scales by page and stays capped', () {
      expect(
        FeedManifestPolicy.resolveSlotLoadBudget(pageNumber: 1),
        FeedManifestPolicy.startupSlotLoadBudget,
      );
      expect(
        FeedManifestPolicy.resolveSlotLoadBudget(pageNumber: 2),
        FeedManifestPolicy.maxSlotLoadBudget,
      );
      expect(
        FeedManifestPolicy.resolveSlotLoadBudget(pageNumber: 99),
        FeedManifestPolicy.maxSlotLoadBudget,
      );
    });

    test('startup visible deck caps gap plus newest-to-oldest slot batches',
        () {
      expect(FeedManifestPolicy.gapSlotBatchSize, 15);
      expect(FeedManifestPolicy.startupSlotLoadBudget, 24);
      expect(FeedManifestPolicy.startupSlotBatchSize, 5);
      expect(FeedManifestPolicy.startupManifestDeckLimit, 120);
      expect(FeedManifestPolicy.startupVisibleDeckLimit, 135);
    });
  });
}
