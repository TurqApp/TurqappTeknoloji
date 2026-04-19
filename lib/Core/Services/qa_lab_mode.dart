import 'integration_test_mode.dart';

class QALabMode {
  static const bool _isIntegrationSmokeRun = bool.fromEnvironment(
    'RUN_INTEGRATION_SMOKE',
    defaultValue: false,
  );
  const QALabMode._();

  static const bool enabled = bool.fromEnvironment(
        'QA_LAB_ENABLED',
        defaultValue: false,
      ) ||
      IntegrationTestMode.enabled;

  static const bool integrationSmokeRun = _isIntegrationSmokeRun;

  static const bool autoStartSession = bool.fromEnvironment(
    'QA_LAB_AUTOSTART',
    defaultValue: enabled,
  );

  static const bool freshStartOnLaunch = bool.fromEnvironment(
    'QA_LAB_FRESH_START',
    defaultValue: enabled && !IntegrationTestMode.enabled,
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

  static const int maxTimelineEvents = int.fromEnvironment(
    'QA_LAB_MAX_TIMELINE_EVENTS',
    defaultValue: 320,
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

  static const bool remoteUploadEnabled = bool.fromEnvironment(
    'QA_LAB_REMOTE_UPLOAD',
    defaultValue: enabled,
  );

  static const String remoteCollectionName = String.fromEnvironment(
    'QA_LAB_REMOTE_COLLECTION',
    defaultValue: 'qa',
  );

  static const String remoteUploadScope = String.fromEnvironment(
    'QA_LAB_REMOTE_SCOPE',
    defaultValue: 'live',
  );

  static const int remoteUploadDebounceMs = int.fromEnvironment(
    'QA_LAB_REMOTE_UPLOAD_DEBOUNCE_MS',
    defaultValue: 2500,
  );

  static const int remoteUploadMaxFindings = int.fromEnvironment(
    'QA_LAB_REMOTE_UPLOAD_MAX_FINDINGS',
    defaultValue: 16,
  );

  static const int remoteUploadMaxTimelineEvents = int.fromEnvironment(
    'QA_LAB_REMOTE_UPLOAD_MAX_TIMELINE',
    defaultValue: 8,
  );

  static const int surfaceWatchdogSeconds = int.fromEnvironment(
    'QA_LAB_SURFACE_WATCHDOG_SECONDS',
    defaultValue: 4,
  );

  static const int autoplayDetectionGraceMs = int.fromEnvironment(
    'QA_LAB_AUTOPLAY_DETECTION_GRACE_MS',
    defaultValue: 3500,
  );

  static const int nativePlaybackPollSeconds = int.fromEnvironment(
    'QA_LAB_NATIVE_PLAYBACK_POLL_SECONDS',
    defaultValue: 2,
  );

  static const int activeIssueLookbackSeconds = int.fromEnvironment(
    'QA_LAB_ACTIVE_ISSUE_LOOKBACK_SECONDS',
    defaultValue: 45,
  );

  static const int duplicateFeedTriggerWindowMs = int.fromEnvironment(
    'QA_LAB_DUPLICATE_FEED_TRIGGER_WINDOW_MS',
    defaultValue: 1400,
  );

  static const int duplicatePlaybackDispatchWindowMs = int.fromEnvironment(
    'QA_LAB_DUPLICATE_PLAYBACK_DISPATCH_WINDOW_MS',
    defaultValue: 900,
  );

  static const int scrollAutoplayDispatchWarningMs = int.fromEnvironment(
    'QA_LAB_SCROLL_AUTOPLAY_DISPATCH_WARNING_MS',
    defaultValue: _isIntegrationSmokeRun ? 900 : 650,
  );

  static const int scrollAutoplayDispatchBlockingMs = int.fromEnvironment(
    'QA_LAB_SCROLL_AUTOPLAY_DISPATCH_BLOCKING_MS',
    defaultValue: 1600,
  );

  static const int scrollFirstFrameWarningMs = int.fromEnvironment(
    'QA_LAB_SCROLL_FIRST_FRAME_WARNING_MS',
    defaultValue: _isIntegrationSmokeRun ? 2400 : 1800,
  );

  static const int scrollFirstFrameBlockingMs = int.fromEnvironment(
    'QA_LAB_SCROLL_FIRST_FRAME_BLOCKING_MS',
    defaultValue: 3600,
  );

  static const int shortVisualStableFrameWarningMs = int.fromEnvironment(
    'QA_LAB_SHORT_VISUAL_STABLE_FRAME_WARNING_MS',
    defaultValue: _isIntegrationSmokeRun ? 550 : 280,
  );

  static const int shortVisualStableFrameBlockingMs = int.fromEnvironment(
    'QA_LAB_SHORT_VISUAL_STABLE_FRAME_BLOCKING_MS',
    defaultValue: 700,
  );

  static const int adLoadWarningMs = int.fromEnvironment(
    'QA_LAB_AD_LOAD_WARNING_MS',
    defaultValue: 1800,
  );

  static const int adLoadBlockingMs = int.fromEnvironment(
    'QA_LAB_AD_LOAD_BLOCKING_MS',
    defaultValue: 4500,
  );
}
