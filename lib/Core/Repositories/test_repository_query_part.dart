part of 'test_repository_library.dart';

extension TestRepositoryQueryPart on TestRepository {
  Future<List<Map<String, dynamic>>> fetchAnswers(
    String testId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'answers:$testId';
    if (!forceRefresh && preferCache) {
      final cached = await _getRawList(cacheKey);
      if (cached != null) return cached;
    }

    if (cacheOnly) return const <Map<String, dynamic>>[];

    final snap = await _firestore
        .collection('Testler')
        .doc(testId)
        .collection('Yanitlar')
        .get();
    final items = snap.docs
        .map((doc) => <String, dynamic>{
              '_docId': doc.id,
              ...doc.data(),
            })
        .toList(growable: false);
    await _storeRawList(cacheKey, items);
    return items;
  }

  Future<List<TestReadinessModel>> fetchQuestions(
    String testId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'questions:$testId';
    if (!forceRefresh && preferCache) {
      final cached = await _getRawList(cacheKey);
      if (cached != null) {
        return cached
            .map(_questionFromMap)
            .whereType<TestReadinessModel>()
            .toList(growable: false);
      }
    }

    if (cacheOnly) return const <TestReadinessModel>[];

    final snap = await _firestore
        .collection('Testler')
        .doc(testId)
        .collection('Sorular')
        .orderBy('id', descending: false)
        .get();
    final items = snap.docs
        .map((doc) => <String, dynamic>{
              '_docId': doc.id,
              ...doc.data(),
            })
        .toList(growable: false);
    await _storeRawList(cacheKey, items);
    return items
        .map(_questionFromMap)
        .whereType<TestReadinessModel>()
        .toList(growable: false);
  }

  Future<List<TestsModel>> fetchByIds(
    List<String> ids, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final wanted = ids.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (wanted.isEmpty) return const <TestsModel>[];
    final resolved = <String, TestsModel>{};
    final missing = <String>[];

    if (preferCache) {
      for (final id in wanted) {
        final memory = _getFromMemory('doc:$id');
        if (memory != null && memory.isNotEmpty) {
          resolved[id] = memory.first;
          continue;
        }
        final disk = await _getTimedFromPrefs('doc:$id');
        if (disk != null && disk.items.isNotEmpty) {
          _memory['doc:$id'] = disk;
          resolved[id] = disk.items.first;
          continue;
        }
        missing.add(id);
      }
    } else {
      missing.addAll(wanted);
    }

    if (cacheOnly) {
      return wanted
          .map((id) => resolved[id])
          .whereType<TestsModel>()
          .toList(growable: false);
    }

    for (final chunk in _chunkIds(missing, 10)) {
      final snap = await _firestore
          .collection('Testler')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final item = _fromDoc(doc.id, doc.data());
        resolved[doc.id] = item;
        await _store('doc:${doc.id}', <TestsModel>[item]);
      }
    }

    return wanted
        .map((id) => resolved[id])
        .whereType<TestsModel>()
        .toList(growable: false);
  }

  Future<List<TestsModel>> fetchByOwner(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'owner:$userId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return disk.items;
      }
    }

    if (cacheOnly) return const <TestsModel>[];

    final snap = await _firestore
        .collection('Testler')
        .where('userID', isEqualTo: userId)
        .get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false)
      ..sort((a, b) =>
          int.tryParse(b.timeStamp)
              ?.compareTo(int.tryParse(a.timeStamp) ?? 0) ??
          0);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<TestsModel>> fetchAnsweredByUser(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'answered:$userId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return disk.items;
      }
    }

    if (cacheOnly) return const <TestsModel>[];

    final snap = await _firestore
        .collectionGroup('Yanitlar')
        .where('userID', isEqualTo: userId)
        .get();
    final testIds = <String>[];
    final seen = <String>{};
    for (final doc in snap.docs) {
      final parent = doc.reference.parent.parent;
      final testId = parent?.id ?? '';
      if (testId.isEmpty) continue;
      if (!seen.add(testId)) continue;
      testIds.add(testId);
    }

    final items = await fetchByIds(
      testIds,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    items.sort((a, b) {
      final aTs = int.tryParse(a.timeStamp) ?? 0;
      final bTs = int.tryParse(b.timeStamp) ?? 0;
      return bTs.compareTo(aTs);
    });
    await _store(cacheKey, items);
    return items;
  }

  Future<List<TestsModel>> fetchFavorites(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'favorites:$userId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return disk.items;
      }
    }

    if (cacheOnly) return const <TestsModel>[];

    final snap = await _firestore
        .collection('Testler')
        .where('favoriler', arrayContains: userId)
        .get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<TestsModel>> fetchAll({
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    const cacheKey = 'all';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return disk.items;
      }
    }
    if (cacheOnly) return const <TestsModel>[];
    final snap = await _firestore.collection('Testler').get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<TestsModel>> fetchByType(
    String testTuru, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'type:${normalizeSearchText(testTuru)}';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return disk.items;
      }
    }
    if (cacheOnly) return const <TestsModel>[];
    final snap = await _firestore
        .collection('Testler')
        .where('testTuru', isEqualTo: testTuru)
        .get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<TestPageResult> fetchSharedPage({
    DocumentSnapshot? startAfter,
    int limit = 30,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final canUseCache = startAfter == null;
    final cacheKey = 'shared:first:$limit';
    if (canUseCache && !forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) {
        return TestPageResult(
          items: memory,
          lastDocument: null,
          hasMore: memory.length >= limit,
        );
      }
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return TestPageResult(
          items: disk.items,
          lastDocument: null,
          hasMore: disk.items.length >= limit,
        );
      }
    }
    if (canUseCache && cacheOnly) {
      return const TestPageResult(
        items: <TestsModel>[],
        lastDocument: null,
        hasMore: false,
      );
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('Testler')
        .where('paylasilabilir', isEqualTo: true)
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    if (canUseCache) {
      await _store(cacheKey, items);
    }
    return TestPageResult(
      items: items,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<Map<String, dynamic>?> fetchRawById(
    String testId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'raw:$testId';
    if (!forceRefresh && preferCache) {
      final raw = await _getRawDoc(cacheKey);
      if (raw != null) return raw;
    }
    final doc = await _firestore.collection('Testler').doc(testId).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    await _storeRawDoc(cacheKey, data);
    return data;
  }
}
