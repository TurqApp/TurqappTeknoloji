import 'package:cloud_firestore/cloud_firestore.dart';

Map<String, dynamic> userScopedMap(
  Map<String, dynamic> data,
  String scope,
) {
  final dynamic raw = data[scope];
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return const <String, dynamic>{};
}

dynamic userField(
  Map<String, dynamic> data, {
  required String key,
  String? scope,
  dynamic fallback,
}) {
  if (scope != null && scope.isNotEmpty) {
    final scoped = userScopedMap(data, scope);
    if (scoped.containsKey(key)) return scoped[key];
  }
  if (data.containsKey(key)) return data[key];
  return fallback;
}

String userString(
  Map<String, dynamic> data, {
  required String key,
  String? scope,
  String fallback = '',
}) {
  final value = userField(data, key: key, scope: scope, fallback: fallback);
  return value?.toString() ?? fallback;
}

int userInt(
  Map<String, dynamic> data, {
  required String key,
  String? scope,
  int fallback = 0,
}) {
  final value = userField(data, key: key, scope: scope, fallback: fallback);
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool userBool(
  Map<String, dynamic> data, {
  required String key,
  String? scope,
  bool fallback = false,
}) {
  final value = userField(data, key: key, scope: scope, fallback: fallback);
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
      return true;
    }
    if (normalized == 'false' || normalized == '0' || normalized == 'no') {
      return false;
    }
  }
  return fallback;
}

Map<String, dynamic> scopedUserUpdate({
  required String scope,
  required Map<String, dynamic> values,
  bool deleteLegacyRootFields = true,
}) {
  final out = <String, dynamic>{};
  for (final entry in values.entries) {
    final key = entry.key.trim();
    if (key.isEmpty) continue;
    out['$scope.$key'] = entry.value;
    if (deleteLegacyRootFields) {
      out[key] = FieldValue.delete();
    }
  }
  return out;
}
