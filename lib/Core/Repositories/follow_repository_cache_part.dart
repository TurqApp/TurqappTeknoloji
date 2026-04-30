part of 'follow_repository.dart';

extension FollowRepositoryCachePart on FollowRepository {
  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(value.trim());
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

  List<String> _sanitizeIds(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  void _handleFollowRepositoryInit() {
    ensureLocalPreferenceRepository().sharedPreferences().then((prefs) {
      _prefs = prefs;
    });
  }

  bool _hasFreshCache(String uid) {
    final entry = _memory[uid];
    if (entry == null) return false;
    final fresh =
        DateTime.now().difference(entry.cachedAt) <= FollowRepository._ttl;
    if (!fresh) {
      _memory.remove(uid);
    }
    return fresh;
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
    if (!fresh && !allowStale) {
      _relationMemory.remove(relationKey);
      return null;
    }
    return entry.ids.toSet();
  }

  Future<Set<String>?> _getRelationFromPrefs(
    String relationKey, {
    required bool allowStale,
  }) async {
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
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
      final ts = _asInt(decoded['t']);
      final list = _sanitizeIds(decoded['ids']);
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
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
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
