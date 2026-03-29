part of 'booklet_repository.dart';

extension BookletRepositoryQueryPart on BookletRepository {
  Future<List<BookletModel>> fetchAll({
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _fetch(
        cacheKey: 'all',
        queryBuilder: () => _firestore.collection('books'),
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<List<BookletModel>> fetchByExamType(
    String sinavTuru, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _fetch(
        cacheKey: 'type:${normalizeSearchText(sinavTuru)}',
        queryBuilder: () => _firestore
            .collection('books')
            .where('sinavTuru', isEqualTo: sinavTuru),
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<List<BookletModel>> fetchByOwner(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _fetch(
        cacheKey: 'owner:${normalizeSearchText(userId)}',
        queryBuilder: () =>
            _firestore.collection('books').where('userID', isEqualTo: userId),
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<BookletPage> fetchPage({
    DocumentSnapshot? startAfter,
    int limit = 30,
    bool cacheOnly = false,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('books')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get(
      GetOptions(source: cacheOnly ? Source.cache : Source.serverAndCache),
    );
    final items = snap.docs
        .map((doc) => BookletModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    return BookletPage(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<List<BookletModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final ids =
        docIds.where((e) => e.trim().isNotEmpty).toList(growable: false);
    if (ids.isEmpty) return const <BookletModel>[];
    final byId = <String, BookletModel>{};
    const chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize > ids.length) ? ids.length : i + chunkSize;
      final chunk = ids.sublist(i, end);
      for (final id in chunk) {
        if (preferCache) {
          final cached = await fetchById(id, preferCache: true);
          if (cached != null) {
            byId[id] = cached;
          }
        }
      }
      final missing = chunk.where((id) => !byId.containsKey(id)).toList();
      if (cacheOnly && missing.isNotEmpty) continue;
      if (missing.isEmpty) continue;
      final snap = await _firestore
          .collection('books')
          .where(FieldPath.documentId, whereIn: missing)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snap.docs) {
        final item = BookletModel.fromMap(doc.data(), doc.id);
        byId[doc.id] = item;
        await _store('doc:${doc.id}', <BookletModel>[item]);
      }
    }
    return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
  }

  Future<BookletModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final key = 'doc:$docId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(key);
      if (memory != null && memory.isNotEmpty) return memory.first;
      final disk = await _getFromPrefs(key);
      if (disk != null && disk.isNotEmpty) {
        final cloned = _cloneItems(disk);
        _memory[key] = _TimedBooklets(
          items: cloned,
          cachedAt: DateTime.now(),
        );
        return _cloneItem(cloned.first);
      }
    }

    if (cacheOnly) return null;

    final doc = await _firestore.collection('books').doc(docId).get();
    if (!doc.exists) return null;
    final item = BookletModel.fromMap(doc.data() ?? const {}, doc.id);
    await _store(key, <BookletModel>[item]);
    return item;
  }

  Future<List<Map<String, dynamic>>> fetchAnswerKeys(
    String bookletId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'answers:$bookletId';
    if (!forceRefresh && preferCache) {
      final cached = await _readRawList(key);
      if (cached != null) return cached;
    }

    final snap = await _firestore
        .collection('books')
        .doc(bookletId)
        .collection('CevapAnahtarlari')
        .get();
    final items = snap.docs
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              'data': Map<String, dynamic>.from(doc.data()),
            })
        .toList(growable: false);
    await _storeRawList(key, items);
    return items;
  }

  Future<List<BookletModel>> _fetch({
    required String cacheKey,
    required Query<Map<String, dynamic>> Function() queryBuilder,
    required bool preferCache,
    required bool forceRefresh,
    required bool cacheOnly,
  }) async {
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        final cloned = _cloneItems(disk);
        _memory[cacheKey] = _TimedBooklets(
          items: cloned,
          cachedAt: DateTime.now(),
        );
        return _cloneItems(cloned);
      }
    }

    if (cacheOnly) return const <BookletModel>[];

    final snap = await queryBuilder().get();
    final items = snap.docs
        .map((doc) => BookletModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }
}
