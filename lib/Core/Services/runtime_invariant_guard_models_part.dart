part of 'runtime_invariant_guard.dart';

class RuntimeInvariantViolation {
  const RuntimeInvariantViolation({
    required this.surface,
    required this.invariantKey,
    required this.message,
    required this.payload,
    required this.recordedAt,
  });

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
      'payload': payload,
      'recordedAt': recordedAt.toUtc().toIso8601String(),
    };
  }
}
