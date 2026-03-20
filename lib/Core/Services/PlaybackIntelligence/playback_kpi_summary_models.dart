class CacheFirstSurfaceSummary {
  const CacheFirstSurfaceSummary({
    required this.eventCount,
    required this.localHitCount,
    required this.warmHitCount,
    required this.liveSuccessCount,
    required this.liveFailCount,
    required this.preservedPreviousCount,
  });

  final int eventCount;
  final int localHitCount;
  final int warmHitCount;
  final int liveSuccessCount;
  final int liveFailCount;
  final int preservedPreviousCount;

  double get localHitRatio => eventCount == 0 ? 0 : localHitCount / eventCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventCount': eventCount,
      'localHitCount': localHitCount,
      'warmHitCount': warmHitCount,
      'liveSuccessCount': liveSuccessCount,
      'liveFailCount': liveFailCount,
      'preservedPreviousCount': preservedPreviousCount,
      'localHitRatio': localHitRatio,
    };
  }
}

class RenderDiffSurfaceSummary {
  const RenderDiffSurfaceSummary({
    required this.eventCount,
    required this.patchEventCount,
    required this.zeroDiffCount,
    required this.averageOperations,
    required this.maxOperations,
  });

  final int eventCount;
  final int patchEventCount;
  final int zeroDiffCount;
  final double averageOperations;
  final int maxOperations;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventCount': eventCount,
      'patchEventCount': patchEventCount,
      'zeroDiffCount': zeroDiffCount,
      'averageOperations': averageOperations,
      'maxOperations': maxOperations,
    };
  }
}

class PlaybackWindowSurfaceSummary {
  const PlaybackWindowSurfaceSummary({
    required this.eventCount,
    required this.averageVisibleCount,
    required this.averageHotCount,
    required this.activeLostCount,
    required this.maxAttachedPlayers,
  });

  final int eventCount;
  final double averageVisibleCount;
  final double averageHotCount;
  final int activeLostCount;
  final int maxAttachedPlayers;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'eventCount': eventCount,
      'averageVisibleCount': averageVisibleCount,
      'averageHotCount': averageHotCount,
      'activeLostCount': activeLostCount,
      'maxAttachedPlayers': maxAttachedPlayers,
    };
  }
}
