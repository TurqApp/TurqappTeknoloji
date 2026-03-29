part of 'qa_lab_recorder.dart';

dynamic _cloneQaLabModelValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _cloneQaLabModelValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map(_cloneQaLabModelValue).toList(growable: false);
  }
  return value;
}

Map<String, dynamic> _cloneQaLabModelMap(Map source) {
  return source.map(
    (key, value) => MapEntry(key.toString(), _cloneQaLabModelValue(value)),
  );
}

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
  QALabIssue({
    required this.id,
    required this.source,
    required this.severity,
    required this.code,
    required this.message,
    required this.timestamp,
    required this.route,
    required this.surface,
    this.stackTrace,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) : metadata = _cloneQaLabModelMap(metadata);

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
      'metadata': _cloneQaLabModelMap(metadata),
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
  QALabCheckpoint({
    required this.id,
    required this.label,
    required this.surface,
    required this.route,
    required this.timestamp,
    required Map<String, dynamic> probe,
    Map<String, dynamic> extra = const <String, dynamic>{},
  }) : probe = _cloneQaLabModelMap(probe),
       extra = _cloneQaLabModelMap(extra);

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
      'probe': _cloneQaLabModelMap(probe),
      'extra': _cloneQaLabModelMap(extra),
    };
  }
}

class QALabTimelineEvent {
  QALabTimelineEvent({
    required this.id,
    required this.category,
    required this.code,
    required this.route,
    required this.surface,
    required this.timestamp,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) : metadata = _cloneQaLabModelMap(metadata);

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
      'metadata': _cloneQaLabModelMap(metadata),
    };
  }
}
