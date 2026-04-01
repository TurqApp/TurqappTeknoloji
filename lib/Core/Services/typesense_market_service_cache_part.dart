part of 'typesense_market_service.dart';

extension TypesenseMarketSearchServiceCachePart
    on TypesenseMarketSearchService {
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

  Future<void> _performInvalidateAll() async {
    _memory.clear();
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs
        .getKeys()
        .where((key) =>
            key.startsWith('${TypesenseMarketSearchService._prefsPrefix}:'))
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> _performInvalidateForMutation({
    String? docId,
    String? userId,
  }) async {
    final normalizedDocId = (docId ?? '').trim();
    final normalizedUserId = (userId ?? '').trim();
    _memory.removeWhere((key, _) {
      if (normalizedDocId.isNotEmpty && key == 'doc:$normalizedDocId') {
        return true;
      }
      if (key.startsWith('doc:')) return false;
      if (normalizedDocId.isNotEmpty &&
          key.contains('docId=$normalizedDocId')) {
        return true;
      }
      if (normalizedUserId.isNotEmpty &&
          key.contains('userId=$normalizedUserId')) {
        return true;
      }
      return true;
    });

    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs.getKeys().where((key) {
      if (!key.startsWith('${TypesenseMarketSearchService._prefsPrefix}:')) {
        return false;
      }
      final scopedKey = key.substring(
        '${TypesenseMarketSearchService._prefsPrefix}:'.length,
      );
      if (normalizedDocId.isNotEmpty && scopedKey == 'doc:$normalizedDocId') {
        return true;
      }
      if (scopedKey.startsWith('doc:')) return false;
      if (normalizedDocId.isNotEmpty &&
          scopedKey.contains('docId=$normalizedDocId')) {
        return true;
      }
      if (normalizedUserId.isNotEmpty &&
          scopedKey.contains('userId=$normalizedUserId')) {
        return true;
      }
      return true;
    }).toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  List<MarketItemModel>? _getFromMemory(String key) {
    final entry = _memory[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.cachedAt) >
        TypesenseMarketSearchService._ttl) {
      _memory.remove(key);
      return null;
    }
    return _cloneMarketItems(entry.items);
  }

  Future<_CachedMarketSearchResult?> _getCachedFromPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = _prefsKey(key);
    final raw = prefs?.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = json.decode(raw);
      if (decodedRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final ts = _asInt(decoded['t']);
      final payload = (decoded['d'] as List<dynamic>?) ?? const <dynamic>[];
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) >
          TypesenseMarketSearchService._ttl) {
        await prefs?.remove(prefsKey);
        return null;
      }
      var shouldPrune = false;
      final items = <MarketItemModel>[];
      for (final rawItem in payload) {
        if (rawItem is! Map) {
          shouldPrune = true;
          continue;
        }
        final item = MarketItemModel.fromJson(
          Map<String, dynamic>.from(rawItem),
        );
        if (item.id.trim().isEmpty) {
          shouldPrune = true;
          continue;
        }
        items.add(item);
      }
      if (shouldPrune) {
        if (items.isEmpty) {
          await prefs?.remove(prefsKey);
          return null;
        }
        await prefs?.setString(
          prefsKey,
          jsonEncode(<String, dynamic>{
            't': ts,
            'd': items.map((item) => item.toJson()).toList(growable: false),
          }),
        );
      }
      return _CachedMarketSearchResult(
        items: _cloneMarketItems(items),
        cachedAt: cachedAt,
      );
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<void> _store(String key, List<MarketItemModel> items) async {
    final cachedAt = DateTime.now();
    final cloned = _cloneMarketItems(items);
    _memory[key] = _CachedMarketSearchResult(
      items: cloned,
      cachedAt: cachedAt,
    );
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(key),
      jsonEncode(<String, dynamic>{
        't': cachedAt.millisecondsSinceEpoch,
        'd': cloned.map((item) => item.toJson()).toList(growable: false),
      }),
    );
  }

  void _seedDocCaches(
    List<MarketItemModel> items, {
    DateTime? cachedAt,
  }) {
    final effectiveCachedAt = cachedAt ?? DateTime.now();
    for (final item in items) {
      _memory['doc:${item.id}'] = _CachedMarketSearchResult(
        items: _cloneMarketItems(<MarketItemModel>[item]),
        cachedAt: effectiveCachedAt,
      );
    }
  }

  List<MarketItemModel> _cloneMarketItems(List<MarketItemModel> items) {
    return items
        .map((item) => MarketItemModel.fromJson(item.toJson()))
        .toList(growable: false);
  }
}
