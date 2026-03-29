part of 'notification_preferences_repository.dart';

extension NotificationPreferencesRepositoryCachePart
    on NotificationPreferencesRepository {
  Future<Map<String, dynamic>?> _getPreferencesImpl(
    String uid, {
    required bool preferCache,
    required bool forceRefresh,
  }) async {
    if (uid.isEmpty) return null;
    final key = _cacheKey(uid);

    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(key);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(key);
      if (disk != null) {
        _memory[key] = _CachedNotificationPreferences(
          data: _cloneNotificationPreferencesMap(disk),
          cachedAt: DateTime.now(),
        );
        return _cloneNotificationPreferencesMap(disk);
      }
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .get();
    final data = _cloneNotificationPreferencesMap(
      doc.data() ?? const <String, dynamic>{},
    );
    await putPreferences(uid, data);
    return _cloneNotificationPreferencesMap(data);
  }

  Stream<Map<String, dynamic>> _watchPreferencesImpl(String uid) async* {
    if (uid.isEmpty) {
      yield const <String, dynamic>{};
      return;
    }

    final cached = await getPreferences(uid, preferCache: true);
    if (cached != null) {
      yield _cloneNotificationPreferencesMap(cached);
    }

    yield* FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .snapshots()
        .asyncMap((snap) async {
      final data = _cloneNotificationPreferencesMap(
        snap.data() ?? const <String, dynamic>{},
      );
      await putPreferences(uid, data);
      return _cloneNotificationPreferencesMap(data);
    });
  }

  Future<void> _putPreferencesImpl(
    String uid,
    Map<String, dynamic> data,
  ) async {
    if (uid.isEmpty) return;
    final key = _cacheKey(uid);
    final cachedAt = DateTime.now();
    final cloned = _cloneNotificationPreferencesMap(data);
    _memory[key] = _CachedNotificationPreferences(
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

  Future<void> _invalidateImpl(String uid) async {
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
        NotificationPreferencesRepository._ttl) {
      _memory.remove(key);
      return null;
    }
    return _cloneNotificationPreferencesMap(entry.data);
  }

  Future<Map<String, dynamic>?> _getFromPrefs(String key) async {
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
      if (DateTime.now().difference(cachedAt) >
          NotificationPreferencesRepository._ttl) {
        await prefs?.remove(prefsKey);
        return null;
      }
      return _cloneNotificationPreferencesMap(data);
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  String _cacheKey(String uid) => 'notifications:$uid';

  String _prefsKey(String key) =>
      '${NotificationPreferencesRepository._prefsPrefix}:$key';

  Map<String, dynamic> _cloneNotificationPreferencesMap(
    Map<String, dynamic> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key, _cloneNotificationPreferencesValue(value)),
    );
  }

  dynamic _cloneNotificationPreferencesValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneNotificationPreferencesValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value
          .map(_cloneNotificationPreferencesValue)
          .toList(growable: false);
    }
    return value;
  }
}
