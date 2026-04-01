part of 'rozet_content.dart';

extension _RozetControllerRuntimeX on RozetController {
  UserSummaryResolver get _userSummaryResolver => UserSummaryResolver.ensure();

  Future<void> loadRozet() async {
    _pruneStaleCache();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cachedColor = RozetController._badgeCache[userID];
    final cachedAt = RozetController._badgeCacheMs[userID] ?? 0;
    final isFresh = cachedColor != null &&
        cachedColor != Colors.transparent &&
        (nowMs - cachedAt) < RozetController._cacheTtlMs;
    if (isFresh) {
      color.value = cachedColor;
      return;
    }
    if (cachedColor != null) {
      color.value = cachedColor;
    }
    await _fetchRozetOnce();
  }

  void _pruneStaleCache() {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final staleKeys = <String>[];
    for (final entry in RozetController._badgeCacheMs.entries) {
      if ((nowMs - entry.value) > RozetController._staleRetentionMs) {
        staleKeys.add(entry.key);
      }
    }
    for (final key in staleKeys) {
      RozetController._badgeCacheMs.remove(key);
      RozetController._badgeCache.remove(key);
    }
  }

  Future<void> _fetchRozetOnce() async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary == null) {
        color.value = Colors.transparent;
        return;
      }
      final mapped = mapRozetToColor(summary.rozet);
      color.value = mapped;
      if (mapped == Colors.transparent) {
        RozetController._badgeCache.remove(userID);
        RozetController._badgeCacheMs.remove(userID);
      } else {
        RozetController._badgeCache[userID] = mapped;
        RozetController._badgeCacheMs[userID] =
            DateTime.now().millisecondsSinceEpoch;
      }
    } catch (_) {
      color.value = Colors.transparent;
    }
  }
}
