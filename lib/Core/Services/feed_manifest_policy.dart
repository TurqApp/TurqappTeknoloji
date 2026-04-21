import 'package:flutter/foundation.dart' show kDebugMode;
import 'dart:math';

class FeedManifestPolicy {
  const FeedManifestPolicy._();

  static const bool primaryEnabled = bool.fromEnvironment(
    'FEED_MANIFEST_PRIMARY',
    defaultValue: kDebugMode,
  );
  static const bool typesenseGapEnabled = true;
  static const Duration primaryLoadTimeout = Duration(milliseconds: 450);
  static const int defaultDeckLimit = 60;
  static const int gapEvery = 6;
  static const int minUserSpacing = 3;
  static const int maxItemsPerUser = 3;
  static const int startupHeadRememberLimit = 20;
  static const int maxGapCandidateLimit = 60;
  static const int minGapCandidateLimit = 20;

  static int resolveDeckSeed({
    required String userId,
    required String manifestId,
    required int startupSeed,
    required int nowMs,
  }) {
    return Object.hash(
      userId.trim(),
      manifestId.trim(),
      startupSeed,
      nowMs ~/ 1000,
    );
  }

  static int resolveGapCandidateLimit(int requestedLimit) {
    if (requestedLimit <= 0) return minGapCandidateLimit;
    return min(max(requestedLimit, minGapCandidateLimit), maxGapCandidateLimit);
  }
}
