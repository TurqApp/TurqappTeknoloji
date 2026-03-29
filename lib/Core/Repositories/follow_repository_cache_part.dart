part of 'follow_repository.dart';

extension FollowRepositoryCachePart on FollowRepository {
  void _handleFollowRepositoryInit() {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  bool _hasFreshCache(String uid) {
    final entry = _memory[uid];
    if (entry == null) return false;
    return DateTime.now().difference(entry.cachedAt) <= FollowRepository._ttl;
  }

  String _prefsKey(String uid) => '${FollowRepository._prefsKeyPrefix}:$uid';

  String _relationKey(String uid, String relation) => '$uid:$relation';

  Set<String>? _getRelationFromMemory(
    String relationKey, {
    required bool allowStale,
  }) {
    final entry = _relationMemory[relationKey];
    if (entry == null) return null;
    final fresh =
        DateTime.now().difference(entry.cachedAt) <= FollowRepository._ttl;
    if (!fresh && !allowStale) return null;
    return entry.ids.toSet();
  }

  Future<Set<String>?> _getRelationFromPrefs(
    String relationKey, {
    required bool allowStale,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = _relationPrefsKey(relationKey);
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
      final list =
          (decoded['ids'] as List?)?.cast<String>() ?? const <String>[];
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final fresh =
          DateTime.now().difference(cachedAt) <= FollowRepository._ttl;
      if (!fresh) {
        if (!allowStale) {
          await prefs?.remove(prefsKey);
        }
        return null;
      }
      return list.toSet();
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<void> _persistRelation(String relationKey, Set<String> ids) async {
    final cachedAt = DateTime.now();
    _relationMemory[relationKey] =
        _CachedFollowingSet(ids: ids.toSet(), cachedAt: cachedAt);
    if (relationKey.endsWith(':followings')) {
      final uid =
          relationKey.substring(0, relationKey.length - ':followings'.length);
      _memory[uid] = _CachedFollowingSet(ids: ids.toSet(), cachedAt: cachedAt);
    }
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _relationPrefsKey(relationKey),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'ids': ids.toList(),
      }),
    );
    if (relationKey.endsWith(':followings')) {
      final uid =
          relationKey.substring(0, relationKey.length - ':followings'.length);
      await _prefs?.setString(
        _prefsKey(uid),
        jsonEncode({
          't': cachedAt.millisecondsSinceEpoch,
          'ids': ids.toList(),
        }),
      );
    }
  }

  String _relationPrefsKey(String relationKey) =>
      '${FollowRepository._relationPrefsKeyPrefix}:$relationKey';
}
