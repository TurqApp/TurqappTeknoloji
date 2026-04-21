import 'dart:math';

class FeedManifestPolicy {
  const FeedManifestPolicy._();

  static const bool primaryEnabled = false;
  static const bool typesenseGapEnabled = true;
  static const int defaultDeckLimit = 60;
  static const int gapEvery = 6;
  static const int minUserSpacing = 3;
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
