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
