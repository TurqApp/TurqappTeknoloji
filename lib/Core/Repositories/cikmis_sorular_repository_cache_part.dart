part of 'cikmis_sorular_repository_parts.dart';

extension _CikmisSorularRepositoryCachePart on _CikmisSorularRepositoryBase {
  Future<List<Map<String, dynamic>>?> _readList(String key) async {
    final memory = _memory[key];
    if (memory != null &&
        DateTime.now().difference(memory.cachedAt) <=
            _cikmisSorularRepositoryTtl) {
      return _cloneItems(memory.items);
    }
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final prefsKey = '$_cikmisSorularRepositoryPrefsPrefix::$key';
    final raw = prefs.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
      if (cachedAt == null ||
          DateTime.now().difference(cachedAt) > _cikmisSorularRepositoryTtl) {
        await prefs.remove(prefsKey);
        return null;
      }
      final items = (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList(growable: false);
      final cloned = _cloneItems(items);
      _memory[key] = _TimedJsonList(items: cloned, cachedAt: DateTime.now());
      return _cloneItems(cloned);
    } catch (_) {
      await prefs.remove(prefsKey);
      return null;
    }
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
    _memory[key] = _TimedJsonList(
      items: _cloneItems(items),
      cachedAt: DateTime.now(),
    );
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
      '$_cikmisSorularRepositoryPrefsPrefix::$key',
      jsonEncode(<String, dynamic>{
        'cachedAt': DateTime.now().toIso8601String(),
        'items': _cloneItems(items),
      }),
    );
  }

  List<Map<String, dynamic>> _cloneItems(List<Map<String, dynamic>> items) {
    return items.map(_cloneItem).toList(growable: false);
  }

  Map<String, dynamic> _cloneItem(Map<String, dynamic> item) {
    return item.map((key, value) => MapEntry(key, _cloneValue(value)));
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

class _TimedJsonList {
  const _TimedJsonList({
    required this.items,
    required this.cachedAt,
  });

  final List<Map<String, dynamic>> items;
  final DateTime cachedAt;
}
