part of 'playback_kpi_service.dart';

enum PlaybackKpiEventType {
  startup,
  cacheFirstLifecycle,
  renderDiff,
  playbackWindow,
  firstFrame,
  rebuffer,
  cacheHitRatio,
  prefetchHealth,
  playbackIntent,
  mobileBytesPerMinute,
  profileLocalHitRatio,
}

class PlaybackKpiEvent {
  final PlaybackKpiEventType type;
  final Map<String, dynamic> payload;

  const PlaybackKpiEvent({
    required this.type,
    required this.payload,
  });
}
