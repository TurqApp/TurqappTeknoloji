import 'dart:convert';

import 'package:turqappv2/Core/Repositories/slider_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Slider/slider_catalog.dart';
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
  final SliderRepository _sliderRepository = ensureSliderRepository();

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

  Future<List<String>> resolveRemoteSources(String sliderId) async {
    final cleanId = sliderId.trim();
    if (cleanId.isEmpty) return const <String>[];
    final remote = await _sliderRepository.fetchSlider(cleanId);
    final metaSnapshot = remote.meta;
    final itemsSnapshot = remote.items;

    final hiddenDefaults =
        ((metaSnapshot.data()?['hiddenDefaults'] as List<dynamic>?) ??
                const <dynamic>[])
            .map((e) => e is num ? e.toInt() : -1)
            .where((e) => e >= 0)
            .toSet();

    final defaults = SliderCatalog.defaultImagesFor(cleanId);
    final remoteByOrder = <int, String>{};
    final extras = <String>[];

    for (final doc in itemsSnapshot.docs) {
      final order = (doc.data()['order'] as num?)?.toInt() ?? 0;
      final url = (doc.data()['imageUrl'] ?? '').toString().trim();
      if (url.isEmpty) continue;
      if (order < defaults.length) {
        remoteByOrder[order] = url;
      } else {
        extras.add(url);
      }
    }

    final resolved = <String>[];
    for (var i = 0; i < defaults.length; i++) {
      if (hiddenDefaults.contains(i) && !remoteByOrder.containsKey(i)) {
        continue;
      }
      final remote = remoteByOrder[i];
      if (remote != null && remote.isNotEmpty) {
        resolved.add(remote);
        continue;
      }
      final fallback = defaults[i];
      if (fallback.isNotEmpty) {
        resolved.add(fallback);
      }
    }
    resolved.addAll(extras);
    return resolved;
  }

  Future<List<String>> refreshAndCacheSources(
    String sliderId, {
    int warmRemoteLimit = 8,
  }) async {
    final resolved = await resolveRemoteSources(sliderId);
    if (resolved.isEmpty) return const <String>[];
    await writeResolvedSources(sliderId, resolved);
    await warmImages(resolved, remoteLimit: warmRemoteLimit);
    return resolved;
  }

  Future<void> warmImages(
    List<String> sources, {
    int remoteLimit = 8,
  }) async {
    for (final url
        in sources.where((e) => e.startsWith('http')).take(remoteLimit)) {
      try {
        await TurqImageCacheManager.instance.getSingleFile(url);
      } catch (_) {}
    }
  }
}
