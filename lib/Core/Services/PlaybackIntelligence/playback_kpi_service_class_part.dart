part of 'playback_kpi_service.dart';

class PlaybackKpiService extends GetxService {
  static PlaybackKpiService ensure() => _ensurePlaybackKpiService();

  static PlaybackKpiService? maybeFind() => _maybeFindPlaybackKpiService();

  final _state = _PlaybackKpiServiceState();

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
