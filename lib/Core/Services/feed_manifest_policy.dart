import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:math';

class FeedManifestPolicy {
  const FeedManifestPolicy._();

  static const bool primaryEnabled = bool.fromEnvironment(
    'FEED_MANIFEST_PRIMARY',
    defaultValue: kDebugMode,
  );
  static const bool typesenseGapEnabled = true;
  static const Duration primaryLoadTimeout = Duration(milliseconds: 1200);
  static const int defaultDeckLimit = 60;
  static const int gapEvery = 12;
  static const int minUserSpacing = 4;
  static const int maxItemsPerUser = 2;
  static const int startupHeadRememberLimit = 60;
  static const int maxGapCandidateLimit = 180;
  static const int minGapCandidateLimit = 60;
  static const int startupSlotLoadBudget = 4;
  static const int maxSlotLoadBudget = 12;

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
}
