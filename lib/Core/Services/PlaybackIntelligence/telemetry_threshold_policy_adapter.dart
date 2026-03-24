import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy.dart';

class _TelemetrySurfaceConfig {
  const _TelemetrySurfaceConfig({
    required this.surface,
    required this.surfaceKeyPrefix,
    this.includeRenderDiff = false,
    this.includePlaybackWindow = false,
  });

  final String surface;
  final String surfaceKeyPrefix;
  final bool includeRenderDiff;
  final bool includePlaybackWindow;
}

class TelemetryThresholdPolicyAdapter {
  const TelemetryThresholdPolicyAdapter._();

  static const List<_TelemetrySurfaceConfig> _surfaceConfigs =
      <_TelemetrySurfaceConfig>[
    _TelemetrySurfaceConfig(
      surface: 'feed',
      surfaceKeyPrefix: 'feed_',
      includeRenderDiff: true,
      includePlaybackWindow: true,
    ),
    _TelemetrySurfaceConfig(
      surface: 'short',
      surfaceKeyPrefix: 'short_',
      includeRenderDiff: true,
      includePlaybackWindow: true,
    ),
    _TelemetrySurfaceConfig(
      surface: 'story',
      surfaceKeyPrefix: 'story_',
    ),
    _TelemetrySurfaceConfig(
      surface: 'profile',
      surfaceKeyPrefix: 'profile_',
    ),
    _TelemetrySurfaceConfig(
      surface: 'notifications',
      surfaceKeyPrefix: 'notifications_',
    ),
    _TelemetrySurfaceConfig(
      surface: 'market',
      surfaceKeyPrefix: 'market_',
    ),
    _TelemetrySurfaceConfig(
      surface: 'jobs',
      surfaceKeyPrefix: 'jobs_',
    ),
    _TelemetrySurfaceConfig(
      surface: 'scholarship',
      surfaceKeyPrefix: 'scholarship_',
    ),
    _TelemetrySurfaceConfig(
      surface: 'practice_exam',
      surfaceKeyPrefix: 'practice_exam_',
    ),
    _TelemetrySurfaceConfig(
      surface: 'answer_key',
      surfaceKeyPrefix: 'answer_key_',
    ),
    _TelemetrySurfaceConfig(
      surface: 'past_question',
      surfaceKeyPrefix: 'past_question_',
    ),
    _TelemetrySurfaceConfig(
      surface: 'tutoring',
      surfaceKeyPrefix: 'tutoring_',
    ),
    _TelemetrySurfaceConfig(
      surface: 'workout',
      surfaceKeyPrefix: 'workout_',
    ),
  ];

  static TelemetryThresholdReport evaluateKpiService(
    PlaybackKpiService service,
  ) {
    return TelemetryThresholdPolicy.evaluateSnapshots(
      buildSnapshots(service),
    );
  }

  static List<String> configuredSurfaces() {
    return _surfaceConfigs
        .map((config) => config.surface)
        .toList(growable: false);
  }

  static List<SurfaceTelemetrySnapshot> buildSnapshots(
    PlaybackKpiService service,
  ) {
    return _surfaceConfigs
        .map(
          (config) => SurfaceTelemetrySnapshot(
            surface: config.surface,
            cacheFirst: service.summarizeCacheFirst(
              surfaceKeyPrefix: config.surfaceKeyPrefix,
            ),
            renderDiff: config.includeRenderDiff
                ? service.summarizeRenderDiff(surface: config.surface)
                : null,
            playbackWindow: config.includePlaybackWindow
                ? service.summarizePlaybackWindow(surface: config.surface)
                : null,
          ),
        )
        .toList(growable: false);
  }

  static Map<String, dynamic> buildCoverageSummary(
    PlaybackKpiService service,
  ) {
    final configured = configuredSurfaces();
    final observed = buildSnapshots(service)
        .where((snapshot) => snapshot.hasSignals)
        .map((snapshot) => snapshot.surface)
        .toList(growable: false);
    final missing = configured
        .where((surface) => !observed.contains(surface))
        .toList(growable: false);
    return <String, dynamic>{
      'configuredSurfaceCount': configured.length,
      'observedSurfaceCount': observed.length,
      'configuredSurfaces': configured,
      'observedSurfaces': observed,
      'unobservedSurfaces': missing,
      'coverageRatio':
          configured.isEmpty ? 1.0 : observed.length / configured.length,
    };
  }
}
