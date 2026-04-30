import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Repositories/local_preference_repository.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class GifLibraryService {
  GifLibraryService._();

  static GifLibraryService? _instance;
  static GifLibraryService? maybeFind() => _instance;

  static GifLibraryService ensure() =>
      maybeFind() ?? (_instance = GifLibraryService._());

  static GifLibraryService get instance => ensure();
  Future<void>? _warmTopCacheFuture;
  static const String _manifestKey = 'giphyGif.globalManifest.v1';

  CollectionReference<Map<String, dynamic>> get _globalCollection =>
      AppFirestore.instance.collection('giphyGif');

  Future<void> recordUsage(
    String url, {
    required String source,
    required String category,
  }) async {
    final cleanUrl = url.trim();
    final uid = CurrentUserService.instance.effectiveUserId;
    if (cleanUrl.isEmpty || uid.isEmpty) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final docId = _stableId(cleanUrl);
    final ref = AppFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('giphyGif')
        .doc(docId);
    final globalRef = _globalCollection.doc(docId);

    final payload = {
      'url': cleanUrl,
      'source': source,
      'category': category,
      'lastUsedAt': now,
      'createdAt': now,
      'useCount': FieldValue.increment(1),
      'lastUsedBy': uid,
    };

    await Future.wait([
      ref.set(payload, SetOptions(merge: true)),
      globalRef.set(payload, SetOptions(merge: true)),
    ]);

    await _updateManifest(cleanUrl, source: source, category: category);
  }

  Future<List<Map<String, dynamic>>> fetchGlobalLibrary({
    int limit = 20,
    String? category,
  }) async {
    final cached = await _loadManifest();
    if (cached.isNotEmpty) {
      return _sortAndLimit(cached, limit: limit, category: category);
    }

    Query<Map<String, dynamic>> query =
        _globalCollection.orderBy('lastUsedAt', descending: true);
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    final snap = await query.limit(limit * 5).get();

    final items = snap.docs
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              ...doc.data(),
            })
        .where((item) => (item['url'] ?? '').toString().trim().isNotEmpty)
        .toList(growable: true);

    await _persistManifest(items);
    return _sortAndLimit(items, limit: limit, category: category);
  }

  Future<void> warmTopGifCache({int limit = 100}) {
    final current = _warmTopCacheFuture;
    if (current != null) return current;

    final future = _warmTopGifCacheInternal(limit: limit);
    _warmTopCacheFuture = future.whenComplete(() {
      _warmTopCacheFuture = null;
    });
    return _warmTopCacheFuture!;
  }

  Future<void> _warmTopGifCacheInternal({required int limit}) async {
    final items = await fetchGlobalLibrary(limit: limit);
    if (items.isEmpty) return;

    await Future.wait(
      items.map((item) async {
        final url = (item['url'] ?? '').toString().trim();
        if (url.isEmpty) return;
        try {
          await TurqImageCacheManager.instance.getSingleFile(url);
        } catch (_) {}
      }),
    );
  }

  String _stableId(String input) {
    var hash = 0;
    for (final codeUnit in input.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return hash.toRadixString(16);
  }

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

  Future<List<Map<String, dynamic>>> _loadManifest() async {
    try {
      final prefs = await ensureLocalPreferenceRepository().sharedPreferences();
      final raw = prefs.getString(_manifestKey);
      if (raw == null || raw.isEmpty) return const <Map<String, dynamic>>[];
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        await prefs.remove(_manifestKey);
        return const <Map<String, dynamic>>[];
      }
      var shouldPrune = false;
      final restored = <Map<String, dynamic>>[];
      for (final rawItem in decoded) {
        if (rawItem is! Map) {
          shouldPrune = true;
          continue;
        }
        final item = Map<String, dynamic>.from(rawItem);
        final url = (item['url'] ?? '').toString().trim();
        if (url.isEmpty) {
          shouldPrune = true;
          continue;
        }
        item['useCount'] = _asInt(item['useCount']);
        item['lastUsedAt'] = _asInt(item['lastUsedAt']);
        item['createdAt'] = _asInt(item['createdAt']);
        restored.add(item);
      }
      if (restored.isEmpty && decoded.isNotEmpty) {
        await prefs.remove(_manifestKey);
      } else if (shouldPrune) {
        await prefs.setString(_manifestKey, jsonEncode(restored));
      }
      return restored;
    } catch (_) {
      try {
        final prefs =
            await ensureLocalPreferenceRepository().sharedPreferences();
        await prefs.remove(_manifestKey);
      } catch (_) {}
      return const <Map<String, dynamic>>[];
    }
  }

  Future<void> _persistManifest(List<Map<String, dynamic>> items) async {
    try {
      final prefs = await ensureLocalPreferenceRepository().sharedPreferences();
      await prefs.setString(_manifestKey, jsonEncode(items));
    } catch (_) {}
  }

  Future<void> _updateManifest(
    String url, {
    required String source,
    required String category,
  }) async {
    final items = await _loadManifest();
    final now = DateTime.now().millisecondsSinceEpoch;
    final idx = items.indexWhere((e) => (e['url'] ?? '').toString() == url);
    if (idx >= 0) {
      final current = Map<String, dynamic>.from(items[idx]);
      current['useCount'] = _asInt(current['useCount']) + 1;
      current['lastUsedAt'] = now;
      current['source'] = source;
      current['category'] = category;
      items[idx] = current;
    } else {
      items.add({
        'id': _stableId(url),
        'url': url,
        'source': source,
        'category': category,
        'createdAt': now,
        'lastUsedAt': now,
        'useCount': 1,
      });
    }
    await _persistManifest(items);
  }

  List<Map<String, dynamic>> _sortAndLimit(
    List<Map<String, dynamic>> items, {
    required int limit,
    String? category,
  }) {
    final filtered = items
        .where((item) => (item['url'] ?? '').toString().trim().isNotEmpty)
        .where((item) =>
            category == null ||
            category.isEmpty ||
            (item['category'] ?? '').toString() == category)
        .toList(growable: true);

    filtered.sort((a, b) {
      final useA = _asInt(a['useCount']);
      final useB = _asInt(b['useCount']);
      final byUse = useB.compareTo(useA);
      if (byUse != 0) return byUse;
      final lastA = _asInt(a['lastUsedAt']);
      final lastB = _asInt(b['lastUsedAt']);
      return lastB.compareTo(lastA);
    });

    if (filtered.length > limit) {
      return filtered.take(limit).toList(growable: false);
    }
    return filtered;
  }
}
