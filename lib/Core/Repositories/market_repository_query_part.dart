part of 'market_repository.dart';

extension MarketRepositoryQueryPart on MarketRepository {
  Future<List<MarketItemModel>> fetchLatestItems({
    int limit = 24,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'latest:$limit';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedMarketItems(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final snapshot = await _fetchLatestSnapshot(limit);
    final items = snapshot.docs
        .map((doc) => MarketItemModel.fromMap(doc.data(), doc.id))
        .where((item) => item.status == 'active')
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<MarketItemModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'doc:$docId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null && memory.isNotEmpty) return memory.first;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null && disk.isNotEmpty) {
        _memory[cacheKey] = _TimedMarketItems(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk.first;
      }
    }

    final doc = await _itemsRef.doc(docId).get(
          const GetOptions(source: Source.serverAndCache),
        );
    if (!doc.exists) return null;
    final item = MarketItemModel.fromMap(doc.data() ?? const {}, doc.id);
    await _store(cacheKey, <MarketItemModel>[item]);
    return item;
  }

  Future<List<MarketItemModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
  }) async {
    final ids = docIds.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <MarketItemModel>[];

    final resolved = <String, MarketItemModel>{};
    final missing = <String>[];

    if (preferCache) {
      for (final id in ids) {
        final memory = _getFromMemory('doc:$id');
        if (memory != null && memory.isNotEmpty) {
          resolved[id] = memory.first;
          continue;
        }
        final disk = await _getFromPrefs('doc:$id');
        if (disk != null && disk.isNotEmpty) {
          _memory['doc:$id'] = _TimedMarketItems(
            items: disk,
            cachedAt: DateTime.now(),
          );
          resolved[id] = disk.first;
          continue;
        }
        missing.add(id);
      }
    } else {
      missing.addAll(ids);
    }

    for (final chunk in _chunkIds(missing, 10)) {
      final snap = await _itemsRef
          .where(FieldPath.documentId, whereIn: chunk)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snap.docs) {
        final item = MarketItemModel.fromMap(doc.data(), doc.id);
        resolved[doc.id] = item;
        await _store('doc:${doc.id}', <MarketItemModel>[item]);
      }
    }

    return ids
        .map((id) => resolved[id])
        .whereType<MarketItemModel>()
        .toList(growable: false);
  }

  Future<List<MarketItemModel>> fetchByOwner(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (uid.trim().isEmpty) return const <MarketItemModel>[];
    final cacheKey = 'owner:$uid';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedMarketItems(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final snapshot = await _fetchOwnerSnapshot(uid);
    final items = snapshot.docs
        .map((doc) => MarketItemModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<MarketItemModel>> fetchSaved(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (uid.trim().isEmpty) return const <MarketItemModel>[];
    final cacheKey = 'saved:$uid';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedMarketItems(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final snapshot = await _fetchSavedRefs(uid);
    final ids = snapshot.docs
        .map((doc) => (doc.data()['itemId'] ?? doc.id).toString())
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false);
    final items = await fetchByIds(ids, preferCache: preferCache);
    final byId = <String, MarketItemModel>{
      for (final item in items) item.id: item,
    };
    final ordered = ids
        .map((id) => byId[id])
        .whereType<MarketItemModel>()
        .toList(growable: false);
    await _store(cacheKey, ordered);
    return ordered;
  }
}
