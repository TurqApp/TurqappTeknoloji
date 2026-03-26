part of 'playback_kpi_service.dart';

PlaybackKpiService? maybeFindPlaybackKpiService() =>
    _maybeFindPlaybackKpiService();

PlaybackKpiService ensurePlaybackKpiService() => _ensurePlaybackKpiService();

PlaybackKpiService? _maybeFindPlaybackKpiService() {
  final isRegistered = Get.isRegistered<PlaybackKpiService>();
  if (!isRegistered) return null;
  return Get.find<PlaybackKpiService>();
}

PlaybackKpiService _ensurePlaybackKpiService() {
  final existing = _maybeFindPlaybackKpiService();
  if (existing != null) return existing;
  return Get.put(PlaybackKpiService(), permanent: true);
}

void _trackPlaybackKpiEvent(
  PlaybackKpiService controller,
  PlaybackKpiEventType type,
  Map<String, dynamic> payload,
) {
  final event = PlaybackKpiEvent(type: type, payload: payload);
  scheduleMicrotask(() {
    _appendPlaybackKpiEvent(controller, event);
  });
  if (kDebugMode && !_suppressPlaybackKpiSmokeLogs) {
    debugPrint('[PlaybackKPI] ${type.name}: $payload');
  }
}

void _appendPlaybackKpiEvent(
  PlaybackKpiService controller,
  PlaybackKpiEvent event,
) {
  controller._recent.add(event);
  if (controller._recent.length > 200) {
    controller._recent.removeRange(0, controller._recent.length - 200);
  }
}
