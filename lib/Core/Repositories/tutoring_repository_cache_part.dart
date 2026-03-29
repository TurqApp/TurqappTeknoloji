part of 'tutoring_repository.dart';

void _handleTutoringRepositoryInit(TutoringRepository repository) {
  SharedPreferences.getInstance().then((prefs) => repository._prefs = prefs);
}

extension TutoringRepositoryCachePart on TutoringRepository {
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
    final value = await _getCachedValue(key);
    if (value is Map<String, dynamic>) return _cloneMap(value);
    return null;
  }

  Future<List<Map<String, dynamic>>?> _getCachedList(String key) async {
    final value = await _getCachedValue(key);
    if (value is List) {
      return value
          .map((e) => _cloneMap(Map<String, dynamic>.from(e as Map)))
          .toList(growable: false);
    }
    return null;
  }

  Future<dynamic> _getCachedValue(String key) async {
    final memory = _memory[key];
    if (memory != null &&
        DateTime.now().difference(memory.cachedAt) <= TutoringRepository._ttl) {
      return _cloneValue(memory.value);
    }
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = '${TutoringRepository._prefsPrefix}:$key';
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
          TutoringRepository._ttl) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final value = decoded['v'];
      _memory[key] = _TimedValue<dynamic>(
          value: _cloneValue(value), cachedAt: DateTime.now());
      return _cloneValue(value);
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<void> _storeMap(String key, Map<String, dynamic> value) =>
      _storeValue(key, value);

  Future<void> _storeValue(String key, dynamic value) async {
    final now = DateTime.now();
    final cloned = _cloneValue(value);
    _memory[key] = _TimedValue<dynamic>(value: cloned, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '${TutoringRepository._prefsPrefix}:$key',
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
