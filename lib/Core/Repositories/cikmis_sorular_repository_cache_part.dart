part of 'cikmis_sorular_repository.dart';

extension _CikmisSorularRepositoryCachePart on CikmisSorularRepository {
  Future<List<Map<String, dynamic>>?> _readList(String key) async {
    final memory = _memory[key];
    if (memory != null &&
        DateTime.now().difference(memory.cachedAt) <=
            CikmisSorularRepository._ttl) {
      return List<Map<String, dynamic>>.from(memory.items);
    }
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw =
        prefs.getString('${CikmisSorularRepository._prefsPrefix}::$key');
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
    if (cachedAt == null ||
        DateTime.now().difference(cachedAt) >
            CikmisSorularRepository._ttl) {
      await prefs
          .remove('${CikmisSorularRepository._prefsPrefix}::$key');
      return null;
    }
    final items = (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    _memory[key] = _TimedJsonList(items: items, cachedAt: DateTime.now());
    return items;
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
    _memory[key] = _TimedJsonList(
      items: List<Map<String, dynamic>>.from(items),
      cachedAt: DateTime.now(),
    );
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
      '${CikmisSorularRepository._prefsPrefix}::$key',
      jsonEncode(<String, dynamic>{
        'cachedAt': DateTime.now().toIso8601String(),
        'items': items,
      }),
    );
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
