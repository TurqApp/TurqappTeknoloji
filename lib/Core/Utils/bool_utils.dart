bool parseFlexibleBool(dynamic raw, {required bool fallback}) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final normalized = raw is String ? raw.trim().toLowerCase() : null;
  if (normalized == null) return fallback;
  if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
    return true;
  }
  if (normalized == 'false' || normalized == '0' || normalized == 'no') {
    return false;
  }
  return fallback;
}
