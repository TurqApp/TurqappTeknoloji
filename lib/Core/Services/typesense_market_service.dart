import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/market_item_model.dart';

class _CachedMarketSearchResult {
  const _CachedMarketSearchResult({
    required this.items,
    required this.cachedAt,
  });

  final List<MarketItemModel> items;
  final DateTime cachedAt;
}

class TypesenseMarketSearchService {
  TypesenseMarketSearchService._();

  static final TypesenseMarketSearchService instance =
      TypesenseMarketSearchService._();
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsPrefix = 'typesense_market_search_v1';

  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'us-central1');
  final Map<String, _CachedMarketSearchResult> _memory =
      <String, _CachedMarketSearchResult>{};
  SharedPreferences? _prefs;

  Future<List<MarketItemModel>> searchItems({
    required String query,
    int limit = 30,
    int page = 1,
    String? docId,
    String? userId,
    String? categoryKey,
    String? city,
    String? district,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final normalized = query.trim().isEmpty ? '*' : query.trim();
    final cacheKey = _searchCacheKey(
      query: normalized,
      limit: limit,
      page: page,
      docId: docId,
      userId: userId,
      categoryKey: categoryKey,
      city: city,
      district: district,
    );

    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getCachedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        _seedDocCaches(disk.items, cachedAt: disk.cachedAt);
        return List<MarketItemModel>.from(disk.items);
      }
    }

    if (cacheOnly) return const <MarketItemModel>[];

    final callable = _functions.httpsCallable('f25_searchMarketCallable');
    final response = await callable.call(<String, dynamic>{
      'q': normalized,
      'limit': limit,
      'page': page,
      if ((docId ?? '').trim().isNotEmpty) 'docId': docId,
      if ((userId ?? '').trim().isNotEmpty) 'userId': userId,
      if ((categoryKey ?? '').trim().isNotEmpty) 'categoryKey': categoryKey,
      if ((city ?? '').trim().isNotEmpty) 'city': city,
      if ((district ?? '').trim().isNotEmpty) 'district': district,
    });

    final data = Map<String, dynamic>.from(response.data as Map? ?? {});
    final hits = (data['hits'] as List<dynamic>?) ?? const [];
    final items = <MarketItemModel>[];

    for (final rawHit in hits) {
      final hitMap = rawHit is Map ? Map<String, dynamic>.from(rawHit) : null;
      if (hitMap == null) continue;
      final docId = (hitMap['docId'] ?? hitMap['id'])?.toString().trim() ?? '';
      if (docId.isEmpty) continue;
      final attributesJson = (hitMap['attributesJson'] ?? '{}').toString();
      Map<String, dynamic> attributes = const <String, dynamic>{};
      try {
        final decoded = json.decode(attributesJson);
        if (decoded is Map) {
          attributes = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
      final sellerPhoneNumber =
          (hitMap['sellerPhoneNumber'] ?? '').toString().trim();
      final contactPreference =
          (hitMap['contactPreference'] ?? 'message_only').toString();
      final showPhone = hitMap['showPhone'] == true ||
          sellerPhoneNumber.isNotEmpty ||
          contactPreference == 'phone';
      items.add(
        MarketItemModel(
          id: docId,
          userId: (hitMap['userId'] ?? '').toString(),
          title: (hitMap['title'] ?? '').toString(),
          description: (hitMap['description'] ?? '').toString(),
          price: (hitMap['price'] as num?)?.toDouble() ?? 0,
          currency: (hitMap['currency'] ?? 'TRY').toString(),
          categoryKey: (hitMap['categoryKey'] ?? '').toString(),
          categoryPath: ((hitMap['categoryPath'] as List<dynamic>?) ?? const [])
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList(growable: false),
          locationText: (hitMap['locationText'] ?? '').toString(),
          city: (hitMap['city'] ?? '').toString(),
          district: (hitMap['district'] ?? '').toString(),
          coverImageUrl: (hitMap['cover'] ?? '').toString(),
          imageUrls: ((hitMap['imageUrls'] as List<dynamic>?) ?? const [])
              .map((e) => e.toString())
              .where((e) => e.trim().isNotEmpty)
              .toList(growable: false),
          sellerName: (hitMap['sellerName'] ?? '').toString(),
          sellerUsername: (hitMap['sellerUsername'] ?? '').toString(),
          sellerPhotoUrl: (hitMap['sellerPhotoUrl'] ?? '').toString(),
          sellerRozet: (hitMap['sellerRozet'] ?? '').toString(),
          sellerPhoneNumber: sellerPhoneNumber,
          showPhone: showPhone,
          contactPreference: contactPreference,
          status: (hitMap['status'] ?? 'active').toString(),
          createdAt: (hitMap['createdAt'] as num?)?.toInt() ?? 0,
          favoriteCount: (hitMap['favoriteCount'] as num?)?.toInt() ?? 0,
          offerCount: (hitMap['offerCount'] as num?)?.toInt() ?? 0,
          viewCount: (hitMap['viewCount'] as num?)?.toInt() ?? 0,
          attributes: attributes,
        ),
      );
    }

    await _store(cacheKey, items);
    _seedDocCaches(items);
    return items;
  }

  Future<MarketItemModel?> fetchByDocId(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final normalizedDocId = docId.trim();
    if (normalizedDocId.isEmpty) return null;
    final cacheKey = 'doc:$normalizedDocId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null && memory.isNotEmpty) return memory.first;
      final disk = await _getCachedFromPrefs(cacheKey);
      if (disk != null && disk.items.isNotEmpty) {
        _memory[cacheKey] = disk;
        return disk.items.first;
      }
    }

    if (cacheOnly) return null;

    final items = await searchItems(
      query: '*',
      limit: 1,
      page: 1,
      docId: normalizedDocId,
      preferCache: preferCache,
      forceRefresh: forceRefresh,
      cacheOnly: cacheOnly,
    );
    if (items.isEmpty) return null;
    return items.first;
  }

  Future<List<MarketItemModel>> fetchByDocIds(
    List<String> docIds, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final ids = docIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (ids.isEmpty) return const <MarketItemModel>[];

    final resolved = <String, MarketItemModel>{};
    final missing = <String>[];

    if (!forceRefresh && preferCache) {
      for (final id in ids) {
        final memory = _getFromMemory('doc:$id');
        if (memory != null && memory.isNotEmpty) {
          resolved[id] = memory.first;
          continue;
        }
        missing.add(id);
      }
    } else {
      missing.addAll(ids);
    }

    for (final id in missing) {
      final item = await fetchByDocId(
        id,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
      );
      if (item != null) {
        resolved[id] = item;
      }
    }

    return ids
        .map((id) => resolved[id])
        .whereType<MarketItemModel>()
        .toList(growable: false);
  }

  Future<List<MarketItemModel>> fetchByUserId(
    String userId, {
    int limit = 60,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return const <MarketItemModel>[];
    return searchItems(
      query: '*',
      limit: limit,
      userId: normalized,
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
  }

  Future<void> invalidateAll() async {
    _memory.clear();
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('$_prefsPrefix:'))
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> invalidateForMutation({
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
      if (normalizedDocId.isNotEmpty && key.contains('docId=$normalizedDocId')) {
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
      if (!key.startsWith('$_prefsPrefix:')) return false;
      final scopedKey = key.substring('$_prefsPrefix:'.length);
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
    if (DateTime.now().difference(entry.cachedAt) > _ttl) {
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
      if (DateTime.now().difference(cachedAt) > _ttl) return null;
      final items = payload
          .whereType<Map>()
          .map((raw) => MarketItemModel.fromJson(Map<String, dynamic>.from(raw)))
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

  String _searchCacheKey({
    required String query,
    required int limit,
    required int page,
    String? docId,
    String? userId,
    String? categoryKey,
    String? city,
    String? district,
  }) {
    return <String>[
      'q=${query.trim()}',
      'limit=$limit',
      'page=$page',
      'docId=${(docId ?? '').trim()}',
      'userId=${(userId ?? '').trim()}',
      'categoryKey=${(categoryKey ?? '').trim()}',
      'city=${(city ?? '').trim()}',
      'district=${(district ?? '').trim()}',
    ].join('|');
  }

  String _prefsKey(String key) => '$_prefsPrefix:$key';
}
