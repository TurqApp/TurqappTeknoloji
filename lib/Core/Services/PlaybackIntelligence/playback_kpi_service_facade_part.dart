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

extension PlaybackKpiServiceFacadePart on PlaybackKpiService {
  List<PlaybackKpiEvent> get recentEvents => List.unmodifiable(_recent);

  void track(PlaybackKpiEventType type, Map<String, dynamic> payload) =>
      _trackPlaybackKpiEvent(this, type, payload);

  CacheFirstSurfaceSummary summarizeCacheFirst({
    required String surfaceKeyPrefix,
    int limit = 60,
  }) =>
      _PlaybackKpiServiceSummaryX(this).summarizeCacheFirst(
        surfaceKeyPrefix: surfaceKeyPrefix,
        limit: limit,
      );

  RenderDiffSurfaceSummary summarizeRenderDiff({
    required String surface,
    int limit = 60,
  }) =>
      _PlaybackKpiServiceSummaryX(this).summarizeRenderDiff(
        surface: surface,
        limit: limit,
      );

  PlaybackWindowSurfaceSummary summarizePlaybackWindow({
    required String surface,
    int limit = 60,
  }) =>
      _PlaybackKpiServiceSummaryX(this).summarizePlaybackWindow(
        surface: surface,
        limit: limit,
      );
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
