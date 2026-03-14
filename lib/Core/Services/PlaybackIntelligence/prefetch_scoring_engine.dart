class PrefetchScoreContext {
  final int basePriority;
  final int currentIndex;
  final int targetIndex;
  final bool isOnWiFi;
  final bool mobileSeedMode;
  final double feedReadyRatio;

  const PrefetchScoreContext({
    required this.basePriority,
    required this.currentIndex,
    required this.targetIndex,
    required this.isOnWiFi,
    required this.mobileSeedMode,
    required this.feedReadyRatio,
  });
}

class PrefetchScoringEngine {
  static double score(PrefetchScoreContext context) {
    final distance = (context.targetIndex - context.currentIndex).abs();

    double score;
    switch (context.basePriority) {
      case 0:
        score = 1000;
        break;
      case 1:
        score = 700;
        break;
      default:
        score = 400;
        break;
    }

    if (context.targetIndex == context.currentIndex) {
      score += 30;
    }

    if (context.targetIndex > context.currentIndex) {
      score += 20;
    }

    score -= distance * 25;

    if (context.isOnWiFi) {
      score += 15;
    }

    if (context.mobileSeedMode) {
      score -= 10;
    }

    if (context.feedReadyRatio < 0.5) {
      score += 20;
    }

    return score;
  }
}
