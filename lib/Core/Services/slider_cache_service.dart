import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class SliderCacheSnapshot {
  final List<String> items;
  final int savedAtMs;

  const SliderCacheSnapshot({
    required this.items,
    required this.savedAtMs,
  });

  bool get hasItems => items.isNotEmpty;

  bool get isFresh {
    if (savedAtMs <= 0) return false;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    return (nowMs - savedAtMs) <= SliderCacheService.ttl.inMilliseconds;
  }
}

class SliderCacheService {
  static const String _keyPrefix = 'slider_cache_v1';
  static const Duration ttl = Duration(days: 7);

  SharedPreferences? _prefs;

  Future<SharedPreferences> _prefsInstance() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  String _key(String sliderId) => '$_keyPrefix::$sliderId';

  Future<SliderCacheSnapshot> readSnapshot(String sliderId) async {
    if (sliderId.trim().isEmpty) {
      return const SliderCacheSnapshot(items: <String>[], savedAtMs: 0);
    }
    try {
      final prefs = await _prefsInstance();
      final raw = prefs.getString(_key(sliderId));
      if (raw == null || raw.trim().isEmpty) {
        return const SliderCacheSnapshot(items: <String>[], savedAtMs: 0);
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const SliderCacheSnapshot(items: <String>[], savedAtMs: 0);
      }

      final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      final items = decoded['items'];
      if (items is! List) {
        return SliderCacheSnapshot(items: const <String>[], savedAtMs: savedAt);
      }

      return SliderCacheSnapshot(
        savedAtMs: savedAt,
        items: items
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false),
      );
    } catch (_) {
      return const SliderCacheSnapshot(items: <String>[], savedAtMs: 0);
    }
  }

  Future<List<String>> readResolvedSources(
    String sliderId, {
    bool allowStale = false,
  }) async {
    final snapshot = await readSnapshot(sliderId);
    if (!snapshot.hasItems) return const <String>[];
    if (!allowStale && !snapshot.isFresh) return const <String>[];
    return snapshot.items;
  }

  Future<void> writeResolvedSources(
    String sliderId,
    List<String> sources,
  ) async {
    if (sliderId.trim().isEmpty || sources.isEmpty) return;
    try {
      final prefs = await _prefsInstance();
      await prefs.setString(
        _key(sliderId),
        jsonEncode({
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'items': sources,
        }),
      );
    } catch (_) {}
  }
}
