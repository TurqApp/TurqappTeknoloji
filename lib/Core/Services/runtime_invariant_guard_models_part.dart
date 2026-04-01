part of 'runtime_invariant_guard.dart';

class RuntimeInvariantViolation {
  RuntimeInvariantViolation({
    required this.surface,
    required this.invariantKey,
    required this.message,
    required Map<String, dynamic> payload,
    required this.recordedAt,
  }) : payload = _cloneRuntimeInvariantPayload(payload);

  final String surface;
  final String invariantKey;
  final String message;
  final Map<String, dynamic> payload;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'surface': surface,
      'invariantKey': invariantKey,
      'message': message,
      'payload': _cloneRuntimeInvariantPayload(payload),
      'recordedAt': recordedAt.toUtc().toIso8601String(),
    };
  }
}

Map<String, dynamic> _cloneRuntimeInvariantPayload(
  Map<String, dynamic> source,
) {
  return source.map(
    (key, value) => MapEntry(key, _cloneRuntimeInvariantValue(value)),
  );
}

dynamic _cloneRuntimeInvariantValue(dynamic value) {
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(
        key.toString(),
        _cloneRuntimeInvariantValue(nestedValue),
      ),
    );
  }
  if (value is List) {
    return value.map(_cloneRuntimeInvariantValue).toList(growable: false);
  }
  return value;
}
