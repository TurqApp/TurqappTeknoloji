import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/playback_kpi_service.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/telemetry_threshold_policy_adapter.dart';
import 'package:turqappv2/Core/Services/integration_test_state_probe.dart';

import 'qa_lab_catalog.dart';
import 'qa_lab_mode.dart';

enum QALabIssueSeverity {
  info,
  warning,
  error,
  blocking,
}

enum QALabIssueSource {
  flutter,
  platform,
  handled,
  cache,
  video,
  route,
  manual,
}

class QALabIssue {
  const QALabIssue({
    required this.id,
    required this.source,
    required this.severity,
    required this.code,
    required this.message,
    required this.timestamp,
    required this.route,
    required this.surface,
    this.stackTrace,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final QALabIssueSource source;
  final QALabIssueSeverity severity;
  final String code;
  final String message;
  final DateTime timestamp;
  final String route;
  final String surface;
  final String? stackTrace;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'source': source.name,
      'severity': severity.name,
      'code': code,
      'message': message,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'route': route,
      'surface': surface,
      'stackTrace': stackTrace,
      'metadata': metadata,
    };
  }
}

class QALabRouteEvent {
  const QALabRouteEvent({
    required this.current,
    required this.previous,
    required this.timestamp,
    required this.surface,
  });

  final String current;
  final String previous;
  final DateTime timestamp;
  final String surface;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'current': current,
      'previous': previous,
      'surface': surface,
      'timestamp': timestamp.toUtc().toIso8601String(),
    };
  }
}

class QALabCheckpoint {
  const QALabCheckpoint({
    required this.id,
    required this.label,
    required this.surface,
    required this.route,
    required this.timestamp,
    required this.probe,
    this.extra = const <String, dynamic>{},
  });

  final String id;
  final String label;
  final String surface;
  final String route;
  final DateTime timestamp;
  final Map<String, dynamic> probe;
  final Map<String, dynamic> extra;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'label': label,
      'surface': surface,
      'route': route,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'probe': probe,
      'extra': extra,
    };
  }
}

class QALabPinpointFinding {
  const QALabPinpointFinding({
    required this.severity,
    required this.code,
    required this.message,
    required this.route,
    required this.surface,
    required this.timestamp,
    this.context = const <String, dynamic>{},
  });

  final QALabIssueSeverity severity;
  final String code;
  final String message;
  final String route;
  final String surface;
  final DateTime timestamp;
  final Map<String, dynamic> context;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'severity': severity.name,
      'code': code,
      'message': message,
      'route': route,
      'surface': surface,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'context': context,
    };
  }
}

class QALabRecorder extends GetxService {
  static QALabRecorder ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(QALabRecorder(), permanent: true);
  }

  static QALabRecorder? maybeFind() {
    final isRegistered = Get.isRegistered<QALabRecorder>();
    if (!isRegistered) return null;
    return Get.find<QALabRecorder>();
  }

  final RxString sessionId = ''.obs;
  final Rxn<DateTime> startedAt = Rxn<DateTime>();
  final RxString lastRoute = ''.obs;
  final RxString lastSurface = ''.obs;
  final RxString lastExportPath = ''.obs;
  final RxList<QALabIssue> issues = <QALabIssue>[].obs;
  final RxList<QALabRouteEvent> routes = <QALabRouteEvent>[].obs;
  final RxList<QALabCheckpoint> checkpoints = <QALabCheckpoint>[].obs;
  Timer? _periodicTimer;

  @override
  void onInit() {
    super.onInit();
    if (QALabMode.autoStartSession) {
      startSession(trigger: 'auto');
    }
  }

  void startSession({String trigger = 'manual'}) {
    sessionId.value = DateTime.now().millisecondsSinceEpoch.toString();
    startedAt.value = DateTime.now();
    lastRoute.value = Get.currentRoute;
    lastSurface.value =
        _inferSurfaceFromSnapshot(IntegrationTestStateProbe.snapshot());
    issues.clear();
    routes.clear();
    checkpoints.clear();
    lastExportPath.value = '';
    _periodicTimer?.cancel();
    if (QALabMode.periodicSnapshots) {
      _periodicTimer = Timer.periodic(
        Duration(seconds: QALabMode.periodicSnapshotSeconds),
        (_) => captureCheckpoint(
          label: 'heartbeat',
          surface: lastSurface.value.isEmpty ? 'app' : lastSurface.value,
          extra: <String, dynamic>{'trigger': trigger},
        ),
      );
    }
    captureCheckpoint(
      label: 'session_started',
      surface: lastSurface.value.isEmpty ? 'app' : lastSurface.value,
      extra: <String, dynamic>{'trigger': trigger},
    );
  }

  void resetSession() {
    startSession(trigger: 'reset');
  }

  void disposeSession() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  void recordRouteChange({
    required String current,
    required String previous,
  }) {
    if (!QALabMode.enabled) return;
    if (sessionId.value.isEmpty) {
      startSession(trigger: 'route');
    }
    final snapshot = IntegrationTestStateProbe.snapshot();
    final surface = _inferSurfaceFromSnapshot(snapshot);
    lastRoute.value = current;
    lastSurface.value = surface;
    routes.add(
      QALabRouteEvent(
        current: current,
        previous: previous,
        timestamp: DateTime.now(),
        surface: surface,
      ),
    );
    _trimList(routes, QALabMode.maxRoutes);
  }

  void recordFlutterError(
    FlutterErrorDetails details, {
    bool suppressed = false,
    String sourceLabel = 'flutter',
  }) {
    final message = details.exceptionAsString();
    recordIssue(
      source: QALabIssueSource.flutter,
      code: suppressed ? 'flutter_suppressed' : 'flutter_error',
      severity: _severityForError(message, suppressed: suppressed),
      message: message,
      stackTrace: details.stack?.toString(),
      metadata: <String, dynamic>{
        'library': details.library ?? '',
        'context': details.context?.toDescription() ?? '',
        'sourceLabel': sourceLabel,
        'suppressed': suppressed,
      },
    );
  }

  void recordPlatformError(
    Object error,
    StackTrace stackTrace, {
    bool suppressed = false,
    String sourceLabel = 'platform',
  }) {
    final message = error.toString();
    recordIssue(
      source: QALabIssueSource.platform,
      code: suppressed ? 'platform_suppressed' : 'platform_error',
      severity: _severityForError(message, suppressed: suppressed),
      message: message,
      stackTrace: stackTrace.toString(),
      metadata: <String, dynamic>{
        'sourceLabel': sourceLabel,
        'errorType': error.runtimeType.toString(),
        'suppressed': suppressed,
      },
    );
  }

  void recordHandledError({
    required String code,
    required String message,
    required String severity,
    required Map<String, dynamic> metadata,
    String? stackTrace,
  }) {
    recordIssue(
      source: QALabIssueSource.handled,
      code: code,
      severity: _severityFromString(severity),
      message: message,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  void recordCacheFirstEvent(Map<String, dynamic> payload) {
    final event = (payload['event'] ?? '').toString();
    final surface = _cacheSurfaceFromPayload(payload);
    if (event.contains('failed')) {
      recordIssue(
        source: QALabIssueSource.cache,
        code: 'cache_first_failed',
        severity: QALabIssueSeverity.warning,
        message: 'Cache-first live sync failed on $surface',
        metadata: payload,
      );
      return;
    }
    if (event == 'liveSyncPreservedPrevious') {
      recordIssue(
        source: QALabIssueSource.cache,
        code: 'cache_first_preserved_previous',
        severity: QALabIssueSeverity.info,
        message: 'Cache-first preserved previous snapshot on $surface',
        metadata: payload,
      );
    }
  }

  void recordVideoEvent({
    required String code,
    required String message,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final severity = code.contains('error') || code.contains('timeout')
        ? QALabIssueSeverity.error
        : QALabIssueSeverity.info;
    recordIssue(
      source: QALabIssueSource.video,
      code: code,
      severity: severity,
      message: message,
      metadata: metadata,
    );
  }

  void captureCheckpoint({
    required String label,
    required String surface,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) {
    if (!QALabMode.enabled) return;
    if (sessionId.value.isEmpty) {
      startSession(trigger: 'checkpoint');
    }
    final snapshot = IntegrationTestStateProbe.snapshot();
    final route = (snapshot['currentRoute'] ?? '').toString();
    checkpoints.add(
      QALabCheckpoint(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        label: label,
        surface: surface,
        route: route,
        timestamp: DateTime.now(),
        probe: snapshot,
        extra: extra,
      ),
    );
    _trimList(checkpoints, QALabMode.maxCheckpoints);
    lastRoute.value = route;
    lastSurface.value = _inferSurfaceFromSnapshot(snapshot);
  }

  void recordIssue({
    required QALabIssueSource source,
    required String code,
    required QALabIssueSeverity severity,
    required String message,
    String? stackTrace,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    if (!QALabMode.enabled) return;
    if (sessionId.value.isEmpty) {
      startSession(trigger: 'issue');
    }
    final snapshot = IntegrationTestStateProbe.snapshot();
    final route = (snapshot['currentRoute'] ?? '').toString();
    final surface = _inferSurfaceFromSnapshot(snapshot);
    issues.add(
      QALabIssue(
        id: '${DateTime.now().microsecondsSinceEpoch}',
        source: source,
        severity: severity,
        code: code,
        message: message,
        timestamp: DateTime.now(),
        route: route,
        surface: surface,
        stackTrace: stackTrace,
        metadata: <String, dynamic>{
          ...metadata,
          'probe': snapshot,
        },
      ),
    );
    _trimList(issues, QALabMode.maxIssues);
    lastRoute.value = route;
    lastSurface.value = surface;
  }

  int get blockingIssueCount => issues
      .where((issue) => issue.severity == QALabIssueSeverity.blocking)
      .length;

  int get errorIssueCount => issues
      .where((issue) => issue.severity == QALabIssueSeverity.error)
      .length;

  int get warningIssueCount => issues
      .where((issue) => issue.severity == QALabIssueSeverity.warning)
      .length;

  int get healthScore {
    final raw = 100 -
        (blockingIssueCount * 25) -
        (errorIssueCount * 10) -
        (warningIssueCount * 4);
    if (raw < 0) return 0;
    if (raw > 100) return 100;
    return raw;
  }

  List<QALabPinpointFinding> buildPinpointFindings() {
    return issues
        .where((issue) => issue.severity != QALabIssueSeverity.info)
        .map(
          (issue) => QALabPinpointFinding(
            severity: issue.severity,
            code: issue.code,
            message: issue.message,
            route: issue.route,
            surface: issue.surface,
            timestamp: issue.timestamp,
            context: <String, dynamic>{
              'source': issue.source.name,
              'lastCheckpoint': _lastCheckpointLabelBefore(issue.timestamp),
            },
          ),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> buildExportJson() {
    final currentSnapshot = IntegrationTestStateProbe.snapshot();
    final playbackKpi = PlaybackKpiService.maybeFind();
    final thresholdReport = playbackKpi == null
        ? const <String, dynamic>{}
        : TelemetryThresholdPolicyAdapter.evaluateKpiService(playbackKpi)
            .toJson();

    return <String, dynamic>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'session': <String, dynamic>{
        'sessionId': sessionId.value,
        'startedAt': startedAt.value?.toUtc().toIso8601String(),
        'lastRoute': lastRoute.value,
        'lastSurface': lastSurface.value,
        'healthScore': healthScore,
        'issueCounts': <String, dynamic>{
          'blocking': blockingIssueCount,
          'error': errorIssueCount,
          'warning': warningIssueCount,
          'info': issues.length -
              blockingIssueCount -
              errorIssueCount -
              warningIssueCount,
        },
      },
      'catalog': <String, dynamic>{
        'summary': QALabCatalog.summaryJson(),
        'entries': QALabCatalog.entries
            .map((entry) => entry.toJson())
            .toList(growable: false),
      },
      'device': _deviceInfoSnapshot(),
      'currentSnapshot': currentSnapshot,
      'routes': routes.map((event) => event.toJson()).toList(growable: false),
      'issues': issues.map((issue) => issue.toJson()).toList(growable: false),
      'pinpointFindings': buildPinpointFindings()
          .map((item) => item.toJson())
          .toList(growable: false),
      'checkpoints': checkpoints
          .map((checkpoint) => checkpoint.toJson())
          .toList(growable: false),
      'telemetryThresholdReport': thresholdReport,
    };
  }

  Future<File> exportSessionJson() async {
    final directory = await getApplicationDocumentsDirectory();
    final qaDir = Directory('${directory.path}/qa_lab');
    if (!qaDir.existsSync()) {
      qaDir.createSync(recursive: true);
    }
    final file = File('${qaDir.path}/qa_report_${sessionId.value}.json');
    final exportJson = buildExportJson();
    exportJson['extendedDeviceInfo'] = await buildExtendedDeviceInfo();
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(exportJson),
    );
    lastExportPath.value = file.path;
    return file;
  }

  Future<void> shareLatestExport() async {
    final file = lastExportPath.value.trim().isNotEmpty
        ? File(lastExportPath.value.trim())
        : await exportSessionJson();
    await SharePlus.instance.share(
      ShareParams(
        files: <XFile>[XFile(file.path)],
        subject: 'TurqApp QA Lab Report',
        text: 'TurqApp QA Lab diagnostic export',
      ),
    );
  }

  Map<String, dynamic> _deviceInfoSnapshot() {
    return <String, dynamic>{
      'platform': defaultTargetPlatform.name,
      'buildMode': kReleaseMode
          ? 'release'
          : kProfileMode
              ? 'profile'
              : 'debug',
    };
  }

  Future<Map<String, dynamic>> buildExtendedDeviceInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo =
        GetPlatform.isAndroid ? await deviceInfo.androidInfo : null;
    final iosInfo = GetPlatform.isIOS ? await deviceInfo.iosInfo : null;
    return <String, dynamic>{
      'package': <String, dynamic>{
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
        'version': packageInfo.version,
        'buildNumber': packageInfo.buildNumber,
      },
      'device': <String, dynamic>{
        if (androidInfo != null) 'manufacturer': androidInfo.manufacturer,
        if (androidInfo != null) 'model': androidInfo.model,
        if (androidInfo != null) 'sdkInt': androidInfo.version.sdkInt,
        if (iosInfo != null) 'name': iosInfo.name,
        if (iosInfo != null) 'model': iosInfo.model,
        if (iosInfo != null) 'systemVersion': iosInfo.systemVersion,
      },
    };
  }

  QALabIssueSeverity _severityForError(
    String message, {
    required bool suppressed,
  }) {
    final lower = message.toLowerCase();
    if (suppressed) return QALabIssueSeverity.info;
    if (lower.contains('improper use of a getx') ||
        lower.contains('failed assertion') ||
        lower.contains('unsupported operation') ||
        lower.contains('null check operator used on a null value')) {
      return QALabIssueSeverity.blocking;
    }
    if (lower.contains('permission-denied')) {
      return QALabIssueSeverity.warning;
    }
    return QALabIssueSeverity.error;
  }

  QALabIssueSeverity _severityFromString(String value) {
    switch (value.trim().toLowerCase()) {
      case 'critical':
        return QALabIssueSeverity.blocking;
      case 'high':
        return QALabIssueSeverity.error;
      case 'medium':
        return QALabIssueSeverity.warning;
      default:
        return QALabIssueSeverity.info;
    }
  }

  String _lastCheckpointLabelBefore(DateTime timestamp) {
    for (final checkpoint in checkpoints.reversed) {
      if (!checkpoint.timestamp.isAfter(timestamp)) {
        return checkpoint.label;
      }
    }
    return '';
  }

  String _cacheSurfaceFromPayload(Map<String, dynamic> payload) {
    final surfaceKey = (payload['surfaceKey'] ?? '').toString();
    if (surfaceKey.startsWith('feed_')) return 'feed';
    if (surfaceKey.startsWith('short_')) return 'short';
    if (surfaceKey.startsWith('notifications_')) return 'notifications';
    if (surfaceKey.startsWith('profile_')) return 'profile';
    return 'cache';
  }

  String _inferSurfaceFromSnapshot(Map<String, dynamic> snapshot) {
    bool registered(String key) =>
        (snapshot[key] as Map<String, dynamic>? ??
            const <String, dynamic>{})['registered'] ==
        true;

    if (registered('storyComments')) return 'story_comments';
    if (registered('comments')) return 'comments';
    if (registered('chatConversation')) return 'chat_conversation';
    if (registered('chat')) return 'chat';
    if (registered('notifications')) return 'notifications';
    if (registered('socialProfile')) return 'social_profile';
    if (registered('profile')) {
      final route = (snapshot['currentRoute'] ?? '').toString();
      if (route.contains('FollowingFollowers')) return 'following_followers';
      if (route.contains('Settings')) return 'settings';
      return 'profile';
    }
    if (registered('short')) return 'short';
    if (registered('education')) return 'pasaj';
    if (registered('explore')) return 'explore';
    if (registered('feed')) return 'feed';
    final route = (snapshot['currentRoute'] ?? '').toString();
    if (route.isNotEmpty) return route;
    return 'app';
  }

  void _trimList<T>(RxList<T> list, int maxCount) {
    if (list.length <= maxCount) return;
    list.removeRange(0, list.length - maxCount);
  }
}
