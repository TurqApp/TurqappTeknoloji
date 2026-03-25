part of 'optical_form_repository.dart';

extension OpticalFormRepositoryCachePart on OpticalFormRepository {
  Future<Map<String, dynamic>?> _getCachedMap(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is Map<String, dynamic>) return cached;
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
      return cached.map((e) => e.toString()).toList(growable: false);
    }
    return null;
  }

  Future<List<Map<String, dynamic>>?> _getCachedList(String key) async {
    final cached = await _getCachedValue(key);
    if (cached is List) {
      return cached
          .map((e) => Map<String, dynamic>.from((e as Map)))
          .toList(growable: false);
    }
    return null;
  }

  Future<dynamic> _getCachedValue(String key) async {
    final memory = _memory[key];
    if (memory != null &&
        DateTime.now().difference(memory.cachedAt) <=
            OpticalFormRepository._ttl) {
      return memory.value;
    }
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('${OpticalFormRepository._prefsPrefix}:$key');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) >
          OpticalFormRepository._ttl) {
        return null;
      }
      final value = decoded['v'];
      _memory[key] = _TimedValue<dynamic>(
        value: value,
        cachedAt: DateTime.now(),
      );
      return value;
    } catch (_) {
      return null;
    }
  }

  Future<void> _storeMap(String key, Map<String, dynamic> value) =>
      _storePrimitive(key, value);

  Future<void> _storePrimitive(String key, dynamic value) async {
    final now = DateTime.now();
    _memory[key] = _TimedValue<dynamic>(value: value, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '${OpticalFormRepository._prefsPrefix}:$key',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'v': value,
      }),
    );
  }
}
