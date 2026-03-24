part of 'qa_lab_recorder.dart';

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
  performance,
  lifecycle,
  permission,
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

class QALabTimelineEvent {
  const QALabTimelineEvent({
    required this.id,
    required this.category,
    required this.code,
    required this.route,
    required this.surface,
    required this.timestamp,
    this.metadata = const <String, dynamic>{},
  });

  final String id;
  final String category;
  final String code;
  final String route;
  final String surface;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'category': category,
      'code': code,
      'route': route,
      'surface': surface,
      'timestamp': timestamp.toUtc().toIso8601String(),
      'metadata': metadata,
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

class QALabSurfaceDiagnostic {
  const QALabSurfaceDiagnostic({
    required this.surface,
    required this.latestRoute,
    required this.healthScore,
    required this.issueCounts,
    required this.coverage,
    required this.runtime,
    required this.findings,
  });

  final String surface;
  final String latestRoute;
  final int healthScore;
  final Map<String, int> issueCounts;
  final QALabSurfaceCoverageReport coverage;
  final Map<String, dynamic> runtime;
  final List<QALabPinpointFinding> findings;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface,
      'latestRoute': latestRoute,
      'healthScore': healthScore,
      'issueCounts': issueCounts,
      'coverage': coverage.toJson(),
      'runtime': runtime,
      'findings': findings.map((item) => item.toJson()).toList(growable: false),
    };
  }
}

class QALabSurfaceAlertSummary {
  const QALabSurfaceAlertSummary({
    required this.surface,
    required this.latestRoute,
    required this.healthScore,
    required this.blockingCount,
    required this.errorCount,
    required this.warningCount,
    required this.findingCount,
    required this.headlineCode,
    required this.headlineMessage,
    required this.primaryRootCauseCategory,
    required this.primaryRootCauseDetail,
  });

  final String surface;
  final String latestRoute;
  final int healthScore;
  final int blockingCount;
  final int errorCount;
  final int warningCount;
  final int findingCount;
  final String headlineCode;
  final String headlineMessage;
  final String primaryRootCauseCategory;
  final String primaryRootCauseDetail;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface,
      'latestRoute': latestRoute,
      'healthScore': healthScore,
      'blockingCount': blockingCount,
      'errorCount': errorCount,
      'warningCount': warningCount,
      'findingCount': findingCount,
      'headlineCode': headlineCode,
      'headlineMessage': headlineMessage,
      'primaryRootCauseCategory': primaryRootCauseCategory,
      'primaryRootCauseDetail': primaryRootCauseDetail,
    };
  }
}
