part of 'offline_mode_service.dart';

class PendingAction {
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final String? dedupeKey;
  final int attemptCount;
  final int nextAttemptAtMs;
  final int lastTriedAtMs;
  final String? lastError;

  PendingAction({
    required this.type,
    required Map<String, dynamic> data,
    DateTime? timestamp,
    this.dedupeKey,
    this.attemptCount = 0,
    this.nextAttemptAtMs = 0,
    this.lastTriedAtMs = 0,
    this.lastError,
  })  : data = _clonePendingActionMap(data),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'type': type,
        'data': _clonePendingActionMap(data),
        'timestamp': timestamp.millisecondsSinceEpoch,
        if (dedupeKey != null && dedupeKey!.isNotEmpty) 'dedupeKey': dedupeKey,
        'attemptCount': attemptCount,
        'nextAttemptAtMs': nextAttemptAtMs,
        'lastTriedAtMs': lastTriedAtMs,
        if (lastError != null && lastError!.isNotEmpty) 'lastError': lastError,
      };

  factory PendingAction.fromJson(Map<String, dynamic> json) {
    return PendingAction(
      type: json['type'],
      data: _clonePendingActionMap(
        Map<String, dynamic>.from(json['data']),
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      dedupeKey: (json['dedupeKey'] ?? '').toString().trim().isEmpty
          ? null
          : json['dedupeKey'].toString(),
      attemptCount: _asInt(json['attemptCount']),
      nextAttemptAtMs: _asInt(json['nextAttemptAtMs']),
      lastTriedAtMs: _asInt(json['lastTriedAtMs']),
      lastError: (json['lastError'] ?? '').toString().trim().isEmpty
          ? null
          : json['lastError'].toString(),
    );
  }

  PendingAction copyWith({
    String? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    String? dedupeKey,
    int? attemptCount,
    int? nextAttemptAtMs,
    int? lastTriedAtMs,
    String? lastError,
  }) {
    return PendingAction(
      type: type ?? this.type,
      data: data != null ? _clonePendingActionMap(data) : this.data,
      timestamp: timestamp ?? this.timestamp,
      dedupeKey: dedupeKey ?? this.dedupeKey,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAtMs: nextAttemptAtMs ?? this.nextAttemptAtMs,
      lastTriedAtMs: lastTriedAtMs ?? this.lastTriedAtMs,
      lastError: lastError ?? this.lastError,
    );
  }

  static int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static Map<String, dynamic> _clonePendingActionMap(
    Map<String, dynamic> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key, _clonePendingActionValue(value)),
    );
  }

  static dynamic _clonePendingActionValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _clonePendingActionValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_clonePendingActionValue).toList(growable: false);
    }
    return value;
  }
}
