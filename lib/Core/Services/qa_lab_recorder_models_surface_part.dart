part of 'qa_lab_recorder.dart';

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
