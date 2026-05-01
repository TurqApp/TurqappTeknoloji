import 'dart:math';

class FeedManifestPolicy {
  const FeedManifestPolicy._();

  static const bool primaryEnabled = bool.fromEnvironment(
    'FEED_MANIFEST_PRIMARY',
    defaultValue: true,
  );
  static const bool typesenseGapEnabled = true;
  static const Duration primaryLoadTimeout = Duration(milliseconds: 3000);
  static const Duration primaryInitialGuestLoadTimeout = Duration(seconds: 16);
  static const int defaultDeckLimit = 60;
  static const int gapEvery = 12;
  static const int gapSlotBatchSize = 15;
  static const Duration gapWindowDelay = Duration(hours: 1);
  static const Duration gapWindowDuration = Duration(hours: 1);
  static const int minUserSpacing = 0;
  static const int maxItemsPerUser = 1000000;
  static const int startupHeadRememberLimit = 60;
  static const int maxGapCandidateLimit = 60;
  static const int minGapCandidateLimit = 60;
  static const int startupSlotLoadBudget = 24;
  static const int maxSlotLoadBudget = 24;

  static int resolveDeckSeed({
    required String userId,
    required String manifestId,
    required int startupSeed,
  }) {
    return Object.hash(
      userId.trim(),
      manifestId.trim(),
      startupSeed,
    );
  }

  static int resolveGapCandidateLimit(int requestedLimit) {
    if (requestedLimit <= 0) return minGapCandidateLimit;
    return min(max(requestedLimit, minGapCandidateLimit), maxGapCandidateLimit);
  }

  static int resolveSlotLoadBudget({
    required int pageNumber,
  }) {
    final normalizedPage = pageNumber < 1 ? 1 : pageNumber;
    return min(
      maxSlotLoadBudget,
      max(startupSlotLoadBudget, normalizedPage * startupSlotLoadBudget),
    );
  }

  static Duration resolvePrimaryLoadTimeout({
    required int pageNumber,
    required bool hasAuthUser,
  }) {
    if (!hasAuthUser && pageNumber <= 1) {
      return Duration.zero;
    }
    return primaryLoadTimeout;
  }
}
