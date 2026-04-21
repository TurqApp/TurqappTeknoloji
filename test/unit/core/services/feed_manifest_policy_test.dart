import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/feed_manifest_policy.dart';

void main() {
  group('FeedManifestPolicy', () {
    test('enables manifest primary by default in debug-mode builds', () {
      expect(FeedManifestPolicy.primaryEnabled, isTrue);
    });

    test(
        'deck seed changes by user, manifest, startup session, and refresh time',
        () {
      final base = FeedManifestPolicy.resolveDeckSeed(
        userId: 'u1',
        manifestId: 'm1',
        startupSeed: 10,
        nowMs: 100000,
      );

      expect(
        FeedManifestPolicy.resolveDeckSeed(
          userId: 'u2',
          manifestId: 'm1',
          startupSeed: 10,
          nowMs: 100000,
        ),
        isNot(base),
      );
      expect(
        FeedManifestPolicy.resolveDeckSeed(
          userId: 'u1',
          manifestId: 'm2',
          startupSeed: 10,
          nowMs: 100000,
        ),
        isNot(base),
      );
      expect(
        FeedManifestPolicy.resolveDeckSeed(
          userId: 'u1',
          manifestId: 'm1',
          startupSeed: 11,
          nowMs: 100000,
        ),
        isNot(base),
      );
      expect(
        FeedManifestPolicy.resolveDeckSeed(
          userId: 'u1',
          manifestId: 'm1',
          startupSeed: 10,
          nowMs: 101000,
        ),
        isNot(base),
      );
    });

    test('gap candidate limit stays bounded', () {
      expect(FeedManifestPolicy.resolveGapCandidateLimit(10), 20);
      expect(FeedManifestPolicy.resolveGapCandidateLimit(40), 40);
      expect(FeedManifestPolicy.resolveGapCandidateLimit(120), 60);
    });

    test('keeps per-user deck cap positive and conservative', () {
      expect(FeedManifestPolicy.maxItemsPerUser, greaterThan(0));
      expect(FeedManifestPolicy.maxItemsPerUser, lessThanOrEqualTo(4));
    });
  });
}
