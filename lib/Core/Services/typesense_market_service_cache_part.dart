part of 'typesense_market_service.dart';

extension TypesenseMarketSearchServiceCachePart
    on TypesenseMarketSearchService {
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
    return List<MarketItemModel>.from(entry.items);
  }

  Future<_CachedMarketSearchResult?> _getCachedFromPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final payload = (decoded['d'] as List<dynamic>?) ?? const <dynamic>[];
      if (ts <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (DateTime.now().difference(cachedAt) >
          TypesenseMarketSearchService._ttl) {
        return null;
      }
      final items = payload
          .whereType<Map>()
          .map(
              (raw) => MarketItemModel.fromJson(Map<String, dynamic>.from(raw)))
          .toList(growable: false);
      return _CachedMarketSearchResult(
        items: items,
        cachedAt: cachedAt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _store(String key, List<MarketItemModel> items) async {
    final cachedAt = DateTime.now();
    final cloned = List<MarketItemModel>.from(items);
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
        items: <MarketItemModel>[item],
        cachedAt: effectiveCachedAt,
      );
    }
  }
}
