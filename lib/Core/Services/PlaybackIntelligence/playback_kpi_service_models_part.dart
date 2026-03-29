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

  PlaybackKpiEvent({
    required this.type,
    required Map<String, dynamic> payload,
  }) : payload = _clonePlaybackKpiPayload(payload);
}

Map<String, dynamic> _clonePlaybackKpiPayload(Map<String, dynamic> source) {
  return source.map(
    (key, value) => MapEntry(key, _clonePlaybackKpiValue(value)),
  );
}

dynamic _clonePlaybackKpiValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _clonePlaybackKpiValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map(_clonePlaybackKpiValue).toList(growable: false);
  }
  return value;
}
