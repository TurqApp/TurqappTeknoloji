import 'package:flutter/foundation.dart';

enum StartupSessionFailureKind {
  startupOrchestration,
  primaryRouteReadiness,
  backgroundWarmup,
  cacheProxyInitialization,
  mediaCacheQuota,
  firstLaunchCleanup,
  authStateRestore,
  authTokenRefresh,
  sessionInitialize,
  sessionForceRefresh,
  sessionSyncStart,
  sessionSyncStream,
  sessionServerValidation,
  accountCenterRegistration,
  exclusiveSessionHandling,
  vaultRead,
  vaultScrub,
}

class StartupSessionFailure {
  const StartupSessionFailure({
    required this.kind,
    required this.operation,
    required this.error,
    this.stackTrace,
  });

  final StartupSessionFailureKind kind;
  final String operation;
  final Object error;
  final StackTrace? stackTrace;

  String get code => kind.name;
}

typedef StartupSessionFailureHandler = void Function(
  StartupSessionFailure failure,
);

class StartupSessionFailureReporter {
  const StartupSessionFailureReporter({this.onFailure});

  final StartupSessionFailureHandler? onFailure;

  static const StartupSessionFailureReporter defaultReporter =
      StartupSessionFailureReporter();

  void record({
    required StartupSessionFailureKind kind,
    required String operation,
    required Object error,
    StackTrace? stackTrace,
  }) {
    final failure = StartupSessionFailure(
      kind: kind,
      operation: operation,
      error: error,
      stackTrace: stackTrace,
    );
    onFailure?.call(failure);
    debugPrint('[startup-session][${failure.code}] $operation :: $error');
    if (kDebugMode && stackTrace != null) {
      debugPrint('$stackTrace');
    }
  }
}
