class FeedTypesensePolicy {
  const FeedTypesensePolicy._();

  static const bool primaryEnabled = true;
  static const bool firestoreFallbackEnabled = false;
  static const int minMotorCandidateLimit = 60;

  static int resolveCandidateLimit(int requestedLimit) {
    return requestedLimit < minMotorCandidateLimit
        ? minMotorCandidateLimit
        : requestedLimit;
  }
}
