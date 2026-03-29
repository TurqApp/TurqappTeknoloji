part of 'user_subcollection_repository.dart';

extension UserSubcollectionRepositoryStoragePart
    on UserSubcollectionRepository {
  Future<void> _setEntriesImpl(
    String uid, {
    required String subcollection,
    required List<UserSubcollectionEntry> items,
  }) async {
    if (uid.isEmpty || subcollection.isEmpty) return;
    final key = _cacheKeyImpl(uid, subcollection);
    final cloned = _cloneEntriesImpl(items);
    final cachedAt = DateTime.now();
    _memory[key] = _CachedUserSubcollection(items: cloned, cachedAt: cachedAt);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKeyImpl(key),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'items': cloned
            .map((e) => {'id': e.id, 'data': e.data})
            .toList(growable: false),
      }),
    );
  }

  Future<void> _invalidateImpl(
    String uid, {
    required String subcollection,
  }) async {
    final key = _cacheKeyImpl(uid, subcollection);
    _memory.remove(key);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKeyImpl(key));
  }

  List<UserSubcollectionEntry>? _getFromMemoryImpl(
    String key, {
    required bool allowStale,
  }) {
    final entry = _memory[key];
    if (entry == null) return null;
    final fresh = DateTime.now().difference(entry.cachedAt) <=
        UserSubcollectionRepository._ttl;
    if (!fresh && !allowStale) {
      _memory.remove(key);
      return null;
    }
    return _cloneEntriesImpl(entry.items);
  }

  Future<List<UserSubcollectionEntry>?> _getFromPrefsImpl(
    String key, {
    required bool allowStale,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = _prefsKeyImpl(key);
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
      final items =
          (decoded['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final fresh = DateTime.now().difference(cachedAt) <=
          UserSubcollectionRepository._ttl;
      if (!fresh) {
        if (!allowStale) {
          await prefs?.remove(prefsKey);
        }
        return null;
      }
      return items
          .map(
            (e) => UserSubcollectionEntry(
              id: (e['id'] ?? '').toString(),
              data: Map<String, dynamic>.from(
                (e['data'] as Map?)?.map((k, v) => MapEntry('$k', v)) ??
                    const <String, dynamic>{},
              ),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  String _cacheKeyImpl(String uid, String subcollection) =>
      '$uid:$subcollection';

  String _prefsKeyImpl(String key) =>
      '${UserSubcollectionRepository._prefsPrefix}:$key';

  List<UserSubcollectionEntry> _cloneEntriesImpl(
    List<UserSubcollectionEntry> items,
  ) {
    return items
        .map(
          (e) => UserSubcollectionEntry(
            id: e.id,
            data: Map<String, dynamic>.from(e.data),
          ),
        )
        .toList(growable: false);
  }
}
