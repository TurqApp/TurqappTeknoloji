part of 'typesense_market_service.dart';

extension TypesenseMarketSearchServiceSearchPart
    on TypesenseMarketSearchService {
  Future<List<MarketItemModel>> _performSearchItems({
    required String query,
    required int limit,
    required int page,
    String? docId,
    String? userId,
    String? categoryKey,
    String? city,
    String? district,
    required bool preferCache,
    required bool forceRefresh,
    required bool cacheOnly,
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
        return _cloneMarketItems(disk.items);
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
          shortId: (hitMap['shortId'] ?? '').toString(),
          shortUrl: (hitMap['shortUrl'] ?? '').toString(),
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

  Future<MarketItemModel?> _performFetchByDocId(
    String docId, {
    required bool preferCache,
    required bool forceRefresh,
    required bool cacheOnly,
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
        return _cloneMarketItems(<MarketItemModel>[disk.items.first]).first;
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

  Future<List<MarketItemModel>> _performFetchByDocIds(
    List<String> docIds, {
    required bool preferCache,
    required bool forceRefresh,
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

  Future<List<MarketItemModel>> _performFetchByUserId(
    String userId, {
    required int limit,
    required bool preferCache,
    required bool forceRefresh,
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
}
