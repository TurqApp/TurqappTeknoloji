part of 'user_subcollection_repository.dart';

extension UserSubcollectionRepositoryStoragePart
    on UserSubcollectionRepository {
  int _asIntImpl(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(value.trim());
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

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
      final ts = _asIntImpl(decoded['t']);
      final items = decoded['items'] is List
          ? List<dynamic>.from(decoded['items'] as List, growable: false)
          : const <dynamic>[];
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
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(
            (e) => UserSubcollectionEntry(
              id: (e['id'] ?? '').toString(),
              data: _cloneUserSubcollectionMap(
                (e['data'] as Map?)?.map((k, v) => MapEntry('$k', v)) ??
                    const <String, dynamic>{},
              ),
            ),
          )
          .where((entry) => entry.id.trim().isNotEmpty)
          .toList(growable: false);
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<List<UserSubcollectionEntry>?> _getCachedEntriesImpl(
    String uid, {
    required String subcollection,
    required bool allowStale,
  }) async {
    if (uid.isEmpty || subcollection.isEmpty) return null;
    final key = _cacheKeyImpl(uid, subcollection);
    final memory = _getFromMemoryImpl(key, allowStale: allowStale);
    if (memory != null) {
      return memory;
    }
    final disk = await _getFromPrefsImpl(key, allowStale: allowStale);
    if (disk == null) return null;
    final cloned = _cloneEntriesImpl(disk);
    _memory[key] = _CachedUserSubcollection(
      items: cloned,
      cachedAt: DateTime.now(),
    );
    return _cloneEntriesImpl(cloned);
  }

  UserSubcollectionEntry? _findEntryInEntriesImpl(
    List<UserSubcollectionEntry> items, {
    required String docId,
  }) {
    for (final entry in items) {
      if (entry.id == docId) {
        return UserSubcollectionEntry(
          id: entry.id,
          data: _cloneUserSubcollectionMap(entry.data),
        );
      }
    }
    return null;
  }

  Future<void> _mergeEntryIntoExistingCacheImpl(
    String uid, {
    required String subcollection,
    required UserSubcollectionEntry entry,
  }) async {
    final current = await _getCachedEntriesImpl(
      uid,
      subcollection: subcollection,
      allowStale: false,
    );
    if (current == null) return;
    final next = List<UserSubcollectionEntry>.from(current)
      ..removeWhere((item) => item.id == entry.id)
      ..add(
        UserSubcollectionEntry(
          id: entry.id,
          data: _cloneUserSubcollectionMap(entry.data),
        ),
      );
    await _setEntriesImpl(uid, subcollection: subcollection, items: next);
  }

  Future<void> _removeEntryFromExistingCacheImpl(
    String uid, {
    required String subcollection,
    required String docId,
  }) async {
    final current = await _getCachedEntriesImpl(
      uid,
      subcollection: subcollection,
      allowStale: false,
    );
    if (current == null) return;
    final next =
        current.where((entry) => entry.id != docId).toList(growable: false);
    await _setEntriesImpl(uid, subcollection: subcollection, items: next);
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
            data: _cloneUserSubcollectionMap(e.data),
          ),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> _cloneUserSubcollectionMap(
    Map<String, dynamic> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key, _cloneUserSubcollectionValue(value)),
    );
  }

  dynamic _cloneUserSubcollectionValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneUserSubcollectionValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneUserSubcollectionValue).toList(growable: false);
    }
    return value;
  }
}
