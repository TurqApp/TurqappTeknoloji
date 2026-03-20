class IntegrationTestMode {
  const IntegrationTestMode._();

  static const bool enabled =
      bool.fromEnvironment('RUN_INTEGRATION_SMOKE', defaultValue: false);

  static const bool deterministicStartup = bool.fromEnvironment(
    'INTEGRATION_DETERMINISTIC_STARTUP',
    defaultValue: enabled,
  );

  static const bool suppressPeriodicSideEffects = bool.fromEnvironment(
    'INTEGRATION_SUPPRESS_PERIODIC_SIDE_EFFECTS',
    defaultValue: enabled,
  );

  static const bool skipBackgroundStartupWork = bool.fromEnvironment(
    'INTEGRATION_SKIP_BACKGROUND_STARTUP_WORK',
    defaultValue: deterministicStartup,
  );

  static const int splashIntroMs = int.fromEnvironment(
    'INTEGRATION_SPLASH_INTRO_MS',
    defaultValue: deterministicStartup ? 0 : 2000,
  );

  static const int splashWatchdogSeconds = int.fromEnvironment(
    'INTEGRATION_SPLASH_WATCHDOG_SECONDS',
    defaultValue: deterministicStartup ? 2 : 0,
  );
}
