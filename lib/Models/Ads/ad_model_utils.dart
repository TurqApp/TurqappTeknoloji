import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseDateTime(dynamic raw) {
  if (raw == null) return null;
  if (raw is Timestamp) return raw.toDate();
  if (raw is DateTime) return raw;
  if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
  if (raw is num) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
  if (raw is String) {
    final asInt = int.tryParse(raw.trim());
    if (asInt != null) return DateTime.fromMillisecondsSinceEpoch(asInt);
    return DateTime.tryParse(raw);
  }
  return null;
}

DateTime parseDateTimeOrNow(dynamic raw) {
  return parseDateTime(raw) ?? DateTime.now();
}

int parseInt(dynamic raw, {int fallback = 0}) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw) ?? fallback;
  return fallback;
}

double parseDouble(dynamic raw, {double fallback = 0}) {
  if (raw is double) return raw;
  if (raw is int) return raw.toDouble();
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw) ?? fallback;
  return fallback;
}

bool parseBool(dynamic raw, {bool fallback = false}) {
  if (raw is bool) return raw;
  if (raw is String) {
    final lower = raw.toLowerCase().trim();
    if (lower == 'true') return true;
    if (lower == 'false') return false;
  }
  return fallback;
}

List<String> parseStringList(dynamic raw) {
  if (raw is! List) return const <String>[];
  return raw
      .whereType<String>()
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();
}

Map<String, dynamic> parseMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return Map<String, dynamic>.from(raw);
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}
