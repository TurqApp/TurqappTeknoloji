import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy.dart';

class TelemetryThresholdPolicyAdapter {
  const TelemetryThresholdPolicyAdapter._();

  static TelemetryThresholdReport evaluateKpiService(
    PlaybackKpiService service,
  ) {
    return TelemetryThresholdPolicy.evaluateSnapshots(
      buildSnapshots(service),
    );
  }

  static List<SurfaceTelemetrySnapshot> buildSnapshots(
    PlaybackKpiService service,
  ) {
    return <SurfaceTelemetrySnapshot>[
      SurfaceTelemetrySnapshot(
        surface: 'feed',
        cacheFirst: service.summarizeCacheFirst(surfaceKeyPrefix: 'feed_'),
        renderDiff: service.summarizeRenderDiff(surface: 'feed'),
        playbackWindow: service.summarizePlaybackWindow(surface: 'feed'),
      ),
      SurfaceTelemetrySnapshot(
        surface: 'short',
        cacheFirst: service.summarizeCacheFirst(surfaceKeyPrefix: 'short_'),
        renderDiff: service.summarizeRenderDiff(surface: 'short'),
        playbackWindow: service.summarizePlaybackWindow(surface: 'short'),
      ),
    ];
  }
}
