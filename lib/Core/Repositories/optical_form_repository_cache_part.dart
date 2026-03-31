part of 'optical_form_repository.dart';

extension OpticalFormRepositoryCachePart on OpticalFormRepository {
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

  Future<Map<String, dynamic>?> _getCachedMap(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is Map<String, dynamic>) return _cloneMap(cached);
    return null;
  }

  Future<int?> _getCachedInt(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is int) return cached;
    return null;
  }

  Future<List<String>?> _getCachedStringList(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is List) {
      return List<String>.from(cached.map((e) => e.toString()));
    }
    return null;
  }

  Future<dynamic> _getCachedValue(String key) async {
    final memory = _memory[key];
    if (memory != null &&
        DateTime.now().difference(memory.cachedAt) <=
            OpticalFormRepository._ttl) {
      return _cloneValue(memory.value);
    }
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = '${OpticalFormRepository._prefsPrefix}:$key';
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
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) >
          OpticalFormRepository._ttl) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final value = decoded['v'];
      _memory[key] = _TimedValue<dynamic>(
        value: _cloneValue(value),
        cachedAt: DateTime.now(),
      );
      return _cloneValue(value);
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<void> _storeMap(String key, Map<String, dynamic> value) =>
      _storePrimitive(key, value);

  Future<void> _storePrimitive(String key, dynamic value) async {
    final now = DateTime.now();
    final cloned = _cloneValue(value);
    _memory[key] = _TimedValue<dynamic>(value: cloned, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '${OpticalFormRepository._prefsPrefix}:$key',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'v': cloned,
      }),
    );
  }

  Map<String, dynamic> _cloneMap(Map<String, dynamic> value) {
    return value.map((key, child) => MapEntry(key, _cloneValue(child)));
  }

  dynamic _cloneValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, child) => MapEntry(key.toString(), _cloneValue(child)),
      );
    }
    if (value is List) {
      return value.map(_cloneValue).toList(growable: false);
    }
    return value;
  }
}
