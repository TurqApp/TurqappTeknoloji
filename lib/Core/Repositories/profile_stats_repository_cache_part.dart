part of 'profile_stats_repository.dart';

class _CachedProfileStats {
  final Map<String, dynamic> data;
  final DateTime cachedAt;

  const _CachedProfileStats({
    required this.data,
    required this.cachedAt,
  });
}

extension ProfileStatsRepositoryCachePart on ProfileStatsRepository {
  Future<Map<String, dynamic>?> getStats(
    String uid, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    if (uid.isEmpty) return null;
    final key = _cacheKey(uid);

    if (preferCache) {
      final memory = _getFromMemory(key);
      if (memory != null) return memory;
      final disk = await _getFromPrefsEntry(key);
      if (disk != null) {
        _memory[key] = _CachedProfileStats(
          data: Map<String, dynamic>.from(disk.data),
          cachedAt: disk.cachedAt,
        );
        return Map<String, dynamic>.from(disk.data);
      }
    }

    if (cacheOnly) return null;

    return null;
  }

  Future<void> setStats(String uid, Map<String, dynamic> data) async {
    if (uid.isEmpty) return;
    final key = _cacheKey(uid);
    final cachedAt = DateTime.now();
    final cloned = Map<String, dynamic>.from(data);
    _memory[key] = _CachedProfileStats(
      data: cloned,
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(key),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'd': cloned,
      }),
    );
  }

  Future<void> invalidate(String uid) async {
    if (uid.isEmpty) return;
    final key = _cacheKey(uid);
    _memory.remove(key);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(key));
  }

  Map<String, dynamic>? _getFromMemory(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) >
        ProfileStatsRepository._ttl) {
      _memory.remove(key);
      return null;
    }
    return Map<String, dynamic>.from(entry.data);
  }

  Future<_CachedProfileStats?> _getFromPrefsEntry(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = _prefsKey(key);
    final raw = prefs?.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final data = (decoded['d'] as Map?)?.cast<String, dynamic>();
      if (ts <= 0 || data == null) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) > ProfileStatsRepository._ttl) {
        await prefs?.remove(prefsKey);
        return null;
      }
      return _CachedProfileStats(
        data: Map<String, dynamic>.from(data),
        cachedAt: cachedAt,
      );
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  String _cacheKey(String uid) => 'stats:$uid';

  String _prefsKey(String key) => '${ProfileStatsRepository._prefsPrefix}:$key';
}
