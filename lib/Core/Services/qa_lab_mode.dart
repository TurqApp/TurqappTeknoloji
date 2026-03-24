import 'integration_test_mode.dart';

class QALabMode {
  const QALabMode._();

  static const bool enabled = bool.fromEnvironment(
        'QA_LAB_ENABLED',
        defaultValue: false,
      ) ||
      IntegrationTestMode.enabled;

  static const bool autoStartSession = bool.fromEnvironment(
    'QA_LAB_AUTOSTART',
    defaultValue: enabled,
  );

  static const bool periodicSnapshots = bool.fromEnvironment(
    'QA_LAB_PERIODIC_SNAPSHOTS',
    defaultValue: enabled,
  );

  static const int periodicSnapshotSeconds = int.fromEnvironment(
    'QA_LAB_PERIODIC_SNAPSHOT_SECONDS',
    defaultValue: 8,
  );

  static const int maxIssues = int.fromEnvironment(
    'QA_LAB_MAX_ISSUES',
    defaultValue: 160,
  );

  static const int maxRoutes = int.fromEnvironment(
    'QA_LAB_MAX_ROUTES',
    defaultValue: 180,
  );

  static const int maxCheckpoints = int.fromEnvironment(
    'QA_LAB_MAX_CHECKPOINTS',
    defaultValue: 80,
  );

  static const int videoFirstFrameTimeoutMs = int.fromEnvironment(
    'QA_LAB_VIDEO_FIRST_FRAME_TIMEOUT_MS',
    defaultValue: 8000,
  );

  static const int videoFirstFrameWarningMs = int.fromEnvironment(
    'QA_LAB_VIDEO_FIRST_FRAME_WARNING_MS',
    defaultValue: 6000,
  );

  static const int videoFirstFrameBlockingMs = int.fromEnvironment(
    'QA_LAB_VIDEO_FIRST_FRAME_BLOCKING_MS',
    defaultValue: 12000,
  );

  static const int videoBufferStallMs = int.fromEnvironment(
    'QA_LAB_VIDEO_BUFFER_STALL_MS',
    defaultValue: 6000,
  );

  static const int frameJankWarningMs = int.fromEnvironment(
    'QA_LAB_FRAME_JANK_WARNING_MS',
    defaultValue: 34,
  );

  static const int frameJankErrorMs = int.fromEnvironment(
    'QA_LAB_FRAME_JANK_ERROR_MS',
    defaultValue: 66,
  );

  static const int frameJankBlockingMs = int.fromEnvironment(
    'QA_LAB_FRAME_JANK_BLOCKING_MS',
    defaultValue: 120,
  );

  static const int noiseBurstWarningCount = int.fromEnvironment(
    'QA_LAB_NOISE_BURST_WARNING_COUNT',
    defaultValue: 3,
  );

  static const bool autoMarkerLogs = bool.fromEnvironment(
    'QA_LAB_AUTO_MARKER_LOGS',
    defaultValue: enabled,
  );

  static const bool autoExportFindings = bool.fromEnvironment(
    'QA_LAB_AUTO_EXPORT_FINDINGS',
    defaultValue: enabled,
  );

  static const int surfaceWatchdogSeconds = int.fromEnvironment(
    'QA_LAB_SURFACE_WATCHDOG_SECONDS',
    defaultValue: 4,
  );

  static const int autoplayDetectionGraceMs = int.fromEnvironment(
    'QA_LAB_AUTOPLAY_DETECTION_GRACE_MS',
    defaultValue: 3500,
  );
}
