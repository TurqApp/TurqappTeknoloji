import 'package:flutter_test/flutter_test.dart';
import 'package:turqappv2/Core/Services/feed_typesense_paging_contract.dart';
import 'package:turqappv2/Core/Services/feed_typesense_policy.dart';

void main() {
  group('FeedTypesensePagingContract', () {
    test('resolveNextTypesensePage returns next page when search has more', () {
      expect(
        FeedTypesensePagingContract.resolveNextTypesensePage(
          itemCount: 60,
          limit: 60,
          page: 1,
          found: 145,
        ),
        2,
      );
    });

    test('resolveNextTypesensePage returns null on last or partial page', () {
      expect(
        FeedTypesensePagingContract.resolveNextTypesensePage(
          itemCount: 42,
          limit: 60,
          page: 1,
          found: 145,
        ),
        isNull,
      );
      expect(
        FeedTypesensePagingContract.resolveNextTypesensePage(
          itemCount: 60,
          limit: 60,
          page: 3,
          found: 180,
        ),
        isNull,
      );
    });

    test('hasContinuation treats typesense page as real continuation', () {
      expect(
        FeedTypesensePagingContract.hasContinuation(
          lastDoc: null,
          nextTypesensePage: 2,
        ),
        isTrue,
      );
      expect(
        FeedTypesensePagingContract.hasContinuation(
          lastDoc: Object(),
          nextTypesensePage: null,
        ),
        isTrue,
      );
      expect(
        FeedTypesensePagingContract.hasContinuation(
          lastDoc: null,
          nextTypesensePage: null,
        ),
        isFalse,
      );
    });

    test(
        'resolvePageHasMore keeps startup flow alive on typesense continuation',
        () {
      expect(
        FeedTypesensePagingContract.resolvePageHasMore(
          initial: true,
          liveConnected: true,
          itemCount: 0,
          sourcePageLimit: 60,
          lastDoc: null,
          nextTypesensePage: 2,
        ),
        isTrue,
      );
    });

    test('resolvePageHasMore requires full page outside initial live bootstrap',
        () {
      expect(
        FeedTypesensePagingContract.resolvePageHasMore(
          initial: false,
          liveConnected: true,
          itemCount: 30,
          sourcePageLimit: 60,
          lastDoc: null,
          nextTypesensePage: 2,
        ),
        isFalse,
      );
      expect(
        FeedTypesensePagingContract.resolvePageHasMore(
          initial: false,
          liveConnected: true,
          itemCount: 60,
          sourcePageLimit: 60,
          lastDoc: null,
          nextTypesensePage: 2,
        ),
        isTrue,
      );
    });

    test(
        'resolveTopUpHasMore remains true when only next typesense page exists',
        () {
      expect(
        FeedTypesensePagingContract.resolveTopUpHasMore(
          itemCount: 0,
          lastDoc: null,
          nextTypesensePage: 3,
        ),
        isTrue,
      );
    });

    test(
        'resolvePlannedHasMore honors typesense continuation without remaining ids',
        () {
      expect(
        FeedTypesensePagingContract.resolvePlannedHasMore(
          hasPlannedRemaining: false,
          canGrowConnectedPlan: false,
          lastDoc: null,
          nextTypesensePage: 4,
        ),
        isTrue,
      );
    });

    test('shouldStopPriming continues while typesense pages remain', () {
      expect(
        FeedTypesensePagingContract.shouldStopPriming(
          plannedCount: 10,
          targetLimit: 30,
          itemCount: 20,
          batchLimit: 20,
          lastDoc: null,
          nextTypesensePage: 2,
        ),
        isFalse,
      );
      expect(
        FeedTypesensePagingContract.shouldStopPriming(
          plannedCount: 10,
          targetLimit: 30,
          itemCount: 20,
          batchLimit: 20,
          lastDoc: null,
          nextTypesensePage: null,
        ),
        isTrue,
      );
    });
  });

  group('Feed typesense policy contract', () {
    test('typesense primary stays enabled and firestore fallback stays off', () {
      expect(FeedTypesensePolicy.primaryEnabled, isTrue);
      expect(FeedTypesensePolicy.firestoreFallbackEnabled, isFalse);
    });

    test('candidate limit honors floor for startup growth', () {
      expect(
        FeedTypesensePolicy.resolveCandidateLimit(10),
        FeedTypesensePolicy.minMotorCandidateLimit,
      );
      expect(
        FeedTypesensePolicy.resolveCandidateLimit(120),
        120,
      );
    });
  });
}
