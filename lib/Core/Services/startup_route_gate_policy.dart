class StartupRouteGatePolicy {
  const StartupRouteGatePolicy._();

  static const int shortReadyTarget = 5;
  static const int shortPrepareTimeoutMs = 900;
  static const int shortReadinessLoopWindowMs = 1200;
  static const int shortReadinessAttemptTimeoutMs = 350;
  static const int shortReadinessPollMs = 60;
  static const int shortActiveAdapterReadyTimeoutMs = 450;

  static const int splashStartupMaxWaitMs = 900;
  static const int splashMinDurationMs = 120;
  static const int splashMinLaunchToNavDurationMs = 0;

  static const int feedStartupPlaybackLockMs = 520;
  static const int androidFeedStartupPlaybackPendingLockMs = 2400;
  static const int androidFeedStartupPlaybackGraceMs = 120;
  static const int androidFeedCurrentRecoveryGraceMs = 1200;
  static const int androidFeedCenteredGapPlaybackGraceMs = 900;
}
