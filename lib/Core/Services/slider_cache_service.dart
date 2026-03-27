import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Repositories/slider_repository.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Slider/slider_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SliderResolvedItem {
  const SliderResolvedItem({
    required this.itemId,
    required this.source,
    required this.order,
    required this.startDateMs,
    required this.endDateMs,
    required this.viewCount,
    required this.uniqueViewCount,
    required this.isRemote,
    required this.isDefault,
  });

  final String itemId;
  final String source;
  final int order;
  final int startDateMs;
  final int endDateMs;
  final int viewCount;
  final int uniqueViewCount;
  final bool isRemote;
  final bool isDefault;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'itemId': itemId,
      'source': source,
      'order': order,
      'startDateMs': startDateMs,
      'endDateMs': endDateMs,
      'viewCount': viewCount,
      'uniqueViewCount': uniqueViewCount,
      'isRemote': isRemote,
      'isDefault': isDefault,
    };
  }

  factory SliderResolvedItem.fromMap(Map<String, dynamic> map) {
    return SliderResolvedItem(
      itemId: (map['itemId'] ?? '').toString(),
      source: (map['source'] ?? '').toString(),
      order: (map['order'] as num?)?.toInt() ?? 0,
      startDateMs: (map['startDateMs'] as num?)?.toInt() ?? 0,
      endDateMs: (map['endDateMs'] as num?)?.toInt() ?? 0,
      viewCount: (map['viewCount'] as num?)?.toInt() ?? 0,
      uniqueViewCount: (map['uniqueViewCount'] as num?)?.toInt() ?? 0,
      isRemote: map['isRemote'] == true,
      isDefault: map['isDefault'] == true,
    );
  }
}

class SliderCacheSnapshot {
  final List<SliderResolvedItem> resolvedItems;
  final int savedAtMs;

  const SliderCacheSnapshot({
    required this.resolvedItems,
    required this.savedAtMs,
  });

  List<String> get items =>
      resolvedItems.map((item) => item.source).toList(growable: false);

  bool get hasItems => resolvedItems.isNotEmpty;

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
      return const SliderCacheSnapshot(
        resolvedItems: <SliderResolvedItem>[],
        savedAtMs: 0,
      );
    }
    try {
      final prefs = await _prefsInstance();
      final raw = prefs.getString(_key(sliderId));
      if (raw == null || raw.trim().isEmpty) {
        return const SliderCacheSnapshot(
          resolvedItems: <SliderResolvedItem>[],
          savedAtMs: 0,
        );
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const SliderCacheSnapshot(
          resolvedItems: <SliderResolvedItem>[],
          savedAtMs: 0,
        );
      }

      final savedAt = (decoded['savedAt'] as num?)?.toInt() ?? 0;
      final resolvedItems = decoded['resolvedItems'];
      if (resolvedItems is List) {
        return SliderCacheSnapshot(
          savedAtMs: savedAt,
          resolvedItems: resolvedItems
              .whereType<Map>()
              .map((item) => SliderResolvedItem.fromMap(
                    Map<String, dynamic>.from(item),
                  ))
              .where((item) => item.source.trim().isNotEmpty)
              .toList(growable: false),
        );
      }

      final legacyItems = decoded['items'];
      if (legacyItems is! List) {
        return SliderCacheSnapshot(
          resolvedItems: const <SliderResolvedItem>[],
          savedAtMs: savedAt,
        );
      }

      return SliderCacheSnapshot(
        savedAtMs: savedAt,
        resolvedItems: legacyItems
            .map((e) => e.toString().trim())
            .where((e) => e.isNotEmpty)
            .toList(growable: false)
            .asMap()
            .entries
            .map(
              (entry) => SliderResolvedItem(
                itemId: 'legacy_${entry.key}',
                source: entry.value,
                order: entry.key,
                startDateMs: 0,
                endDateMs: 0,
                viewCount: 0,
                uniqueViewCount: 0,
                isRemote: entry.value.startsWith('http'),
                isDefault: !entry.value.startsWith('http'),
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {
      return const SliderCacheSnapshot(
        resolvedItems: <SliderResolvedItem>[],
        savedAtMs: 0,
      );
    }
  }

  Future<List<SliderResolvedItem>> readResolvedItems(
    String sliderId, {
    bool allowStale = false,
  }) async {
    final snapshot = await readSnapshot(sliderId);
    if (!snapshot.hasItems) return const <SliderResolvedItem>[];
    if (!allowStale && !snapshot.isFresh) {
      return const <SliderResolvedItem>[];
    }
    return snapshot.resolvedItems;
  }

  Future<List<String>> readResolvedSources(
    String sliderId, {
    bool allowStale = false,
  }) async {
    final items = await readResolvedItems(sliderId, allowStale: allowStale);
    return items.map((item) => item.source).toList(growable: false);
  }

  Future<void> writeResolvedItems(
    String sliderId,
    List<SliderResolvedItem> items,
  ) async {
    if (sliderId.trim().isEmpty) return;
    try {
      final prefs = await _prefsInstance();
      await prefs.setString(
        _key(sliderId),
        jsonEncode({
          'savedAt': DateTime.now().millisecondsSinceEpoch,
          'resolvedItems': items.map((item) => item.toMap()).toList(),
        }),
      );
    } catch (_) {}
  }

  Future<void> clearResolvedItems(String sliderId) async {
    if (sliderId.trim().isEmpty) return;
    try {
      final prefs = await _prefsInstance();
      await prefs.remove(_key(sliderId));
    } catch (_) {}
  }

  Future<void> writeResolvedSources(
    String sliderId,
    List<String> sources,
  ) async {
    if (sliderId.trim().isEmpty || sources.isEmpty) return;
    await writeResolvedItems(
      sliderId,
      sources
          .asMap()
          .entries
          .map(
            (entry) => SliderResolvedItem(
              itemId: 'legacy_${entry.key}',
              source: entry.value,
              order: entry.key,
              startDateMs: 0,
              endDateMs: 0,
              viewCount: 0,
              uniqueViewCount: 0,
              isRemote: entry.value.startsWith('http'),
              isDefault: !entry.value.startsWith('http'),
            ),
          )
          .toList(growable: false),
    );
  }

  Future<List<SliderResolvedItem>> resolveRemoteItems(String sliderId) async {
    final cleanId = sliderId.trim();
    if (cleanId.isEmpty) return const <SliderResolvedItem>[];
    final remote = await _sliderRepository.fetchSlider(cleanId);
    final metaSnapshot = remote.meta;
    final itemsSnapshot = remote.items;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final hiddenDefaults =
        ((metaSnapshot.data()?['hiddenDefaults'] as List<dynamic>?) ??
                const <dynamic>[])
            .map((e) => e is num ? e.toInt() : -1)
            .where((e) => e >= 0)
            .toSet();

    final defaults = SliderCatalog.defaultImagesFor(cleanId);
    final remoteByOrder = <int, SliderResolvedItem>{};
    final extras = <SliderResolvedItem>[];

    for (final doc in itemsSnapshot.docs) {
      final order = (doc.data()['order'] as num?)?.toInt() ?? 0;
      final url = (doc.data()['imageUrl'] ?? '').toString().trim();
      if (url.isEmpty) continue;
      final startDateMs = _readDateMs(doc.data()['startDate']);
      final endDateMs = _readDateMs(doc.data()['endDate']);
      final startsLater = startDateMs > 0 && startDateMs > nowMs;
      final ended = endDateMs > 0 && endDateMs < nowMs;
      if (startsLater || ended) {
        continue;
      }
      final item = SliderResolvedItem(
        itemId: doc.id,
        source: url,
        order: order,
        startDateMs: startDateMs,
        endDateMs: endDateMs,
        viewCount: (doc.data()['viewCount'] as num?)?.toInt() ?? 0,
        uniqueViewCount: (doc.data()['uniqueViewCount'] as num?)?.toInt() ?? 0,
        isRemote: true,
        isDefault: false,
      );
      if (order < defaults.length) {
        remoteByOrder[order] = item;
      } else {
        extras.add(item);
      }
    }

    final resolved = <SliderResolvedItem>[];
    for (var i = 0; i < defaults.length; i++) {
      if (hiddenDefaults.contains(i) && !remoteByOrder.containsKey(i)) {
        continue;
      }
      final remote = remoteByOrder[i];
      if (remote != null && remote.source.isNotEmpty) {
        resolved.add(remote);
        continue;
      }
      final fallback = defaults[i];
      if (fallback.isNotEmpty) {
        resolved.add(
          SliderResolvedItem(
            itemId: 'default_$i',
            source: fallback,
            order: i,
            startDateMs: 0,
            endDateMs: 0,
            viewCount: 0,
            uniqueViewCount: 0,
            isRemote: false,
            isDefault: true,
          ),
        );
      }
    }
    extras.sort((a, b) => a.order.compareTo(b.order));
    resolved.addAll(extras);
    return resolved;
  }

  Future<List<String>> resolveRemoteSources(String sliderId) async {
    final items = await resolveRemoteItems(sliderId);
    return items.map((item) => item.source).toList(growable: false);
  }

  Future<List<SliderResolvedItem>> refreshAndCacheItems(
    String sliderId, {
    int warmRemoteLimit = 8,
  }) async {
    final resolved = await resolveRemoteItems(sliderId);
    await writeResolvedItems(sliderId, resolved);
    if (resolved.isEmpty) return const <SliderResolvedItem>[];
    await warmImages(
      resolved.map((item) => item.source).toList(growable: false),
      remoteLimit: warmRemoteLimit,
    );
    return resolved;
  }

  Future<List<String>> refreshAndCacheSources(
    String sliderId, {
    int warmRemoteLimit = 8,
  }) async {
    final resolved = await refreshAndCacheItems(
      sliderId,
      warmRemoteLimit: warmRemoteLimit,
    );
    return resolved.map((item) => item.source).toList(growable: false);
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

  int _readDateMs(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null) return parsed;
      final date = DateTime.tryParse(value);
      if (date != null) return date.millisecondsSinceEpoch;
    }
    return 0;
  }
}
