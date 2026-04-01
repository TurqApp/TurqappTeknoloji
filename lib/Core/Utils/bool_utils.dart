bool parseFlexibleBool(dynamic raw, {required bool fallback}) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final normalized = raw is String ? raw.trim().toLowerCase() : null;
  if (normalized == null) return fallback;
  if (const {'true', '1', 'yes'}.contains(normalized)) return true;
  if (const {'false', '0', 'no'}.contains(normalized)) return false;
  return fallback;
}
