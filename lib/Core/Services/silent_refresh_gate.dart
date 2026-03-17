class SilentRefreshGate {
  SilentRefreshGate._();

  static final Map<String, DateTime> _lastRefreshAtByKey = <String, DateTime>{};

  static bool shouldRefresh(
    String key, {
    required Duration minInterval,
  }) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) return true;
    final last = _lastRefreshAtByKey[normalizedKey];
    if (last == null) return true;
    return DateTime.now().difference(last) >= minInterval;
  }

  static void markRefreshed(String key) {
    final normalizedKey = key.trim();
    if (normalizedKey.isEmpty) return;
    _lastRefreshAtByKey[normalizedKey] = DateTime.now();
  }
}
