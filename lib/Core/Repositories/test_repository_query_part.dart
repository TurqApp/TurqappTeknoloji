part of 'test_repository_parts.dart';

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
          final cloned = _cloneItems(disk.items);
          _memory['doc:$id'] = _TimedTests(
            items: cloned,
            cachedAt: disk.cachedAt,
          );
          resolved[id] = _cloneItem(cloned.first);
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
