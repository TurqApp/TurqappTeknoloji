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
}
