part of 'practice_exam_repository.dart';

extension PracticeExamRepositoryQueryPart on PracticeExamRepository {
  int _asPracticeExamTimestamp(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  Future<List<SinavModel>> fetchByExamType(
    String sinavTuru, {
    int limit = ReadBudgetRegistry.practiceExamTypeInitialLimit,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'type:${normalizeSearchText(sinavTuru)}:$limit';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        final cloned = _cloneItems(disk);
        _memory[cacheKey] = _TimedPracticeExams(
          items: cloned,
          cachedAt: DateTime.now(),
        );
        return _cloneItems(cloned);
      }
    }

    if (cacheOnly) return const <SinavModel>[];

    final snap = await _firestore
        .collection('practiceExams')
        .where('sinavTuru', isEqualTo: sinavTuru)
        .limit(limit)
        .get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<SinavModel>> fetchAll({
    int limit = ReadBudgetRegistry.practiceExamHomeInitialLimit,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'all:$limit';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        final cloned = _cloneItems(disk);
        _memory[cacheKey] = _TimedPracticeExams(
          items: cloned,
          cachedAt: DateTime.now(),
        );
        return _cloneItems(cloned);
      }
    }

    final snap = await _firestore
        .collection('practiceExams')
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<SinavModel>> fetchByOwner(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return const <SinavModel>[];
    final cacheKey = 'owner:$normalizedUserId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        final cloned = _cloneItems(disk);
        _memory[cacheKey] = _TimedPracticeExams(
          items: cloned,
          cachedAt: DateTime.now(),
        );
        return _cloneItems(cloned);
      }
    }

    final snap = await _firestore
        .collection('practiceExams')
        .where('userID', isEqualTo: normalizedUserId)
        .get();
    final items = snap.docs
      ..sort((a, b) {
        final aTs = _asPracticeExamTimestamp(a.data()['timeStamp']);
        final bTs = _asPracticeExamTimestamp(b.data()['timeStamp']);
        return bTs.compareTo(aTs);
      });
    final models = items
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, models);
    return models;
  }

  Future<PracticeExamPage> fetchPage({
    DocumentSnapshot? startAfter,
    int limit = 30,
    bool cacheOnly = false,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('practiceExams')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get(
      GetOptions(source: cacheOnly ? Source.cache : Source.serverAndCache),
    );
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    return PracticeExamPage(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<SinavModel?> fetchById(
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
        final cloned = _cloneItems(disk);
        _memory[cacheKey] = _TimedPracticeExams(
          items: cloned,
          cachedAt: DateTime.now(),
        );
        return _cloneItem(cloned.first);
      }
    }

    final doc = await _firestore.collection('practiceExams').doc(docId).get();
    if (!doc.exists) return null;
    final item = _fromDoc(doc.id, doc.data() ?? const {});
    await _store(cacheKey, <SinavModel>[item]);
    return item;
  }

  Future<Map<String, dynamic>?> fetchRawById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'raw:$docId';
    if (!forceRefresh && preferCache) {
      final raw = await _getRawDoc(cacheKey);
      if (raw != null) return raw;
    }

    final doc = await _firestore.collection('practiceExams').doc(docId).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    await _storeRawDoc(cacheKey, data);
    return data;
  }

  Future<List<SinavModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final ids = docIds.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <SinavModel>[];

    final resolved = <String, SinavModel>{};
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
          final cloned = _cloneItems(disk);
          _memory['doc:$id'] = _TimedPracticeExams(
            items: cloned,
            cachedAt: DateTime.now(),
          );
          resolved[id] = _cloneItem(cloned.first);
          continue;
        }
        missing.add(id);
      }
    } else {
      missing.addAll(ids);
    }

    if (cacheOnly) {
      return ids
          .map((id) => resolved[id])
          .whereType<SinavModel>()
          .toList(growable: false);
    }

    for (final chunk in _chunkIds(missing, 10)) {
      final snap = await _firestore
          .collection('practiceExams')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final item = _fromDoc(doc.id, doc.data());
        resolved[doc.id] = item;
        await _store('doc:${doc.id}', <SinavModel>[item]);
      }
    }

    return ids
        .map((id) => resolved[id])
        .whereType<SinavModel>()
        .toList(growable: false);
  }

  Future<List<SinavModel>> fetchAnsweredByUser(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return const <SinavModel>[];
    final cacheKey = 'answered:$normalizedUserId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        final cloned = _cloneItems(disk);
        _memory[cacheKey] = _TimedPracticeExams(
          items: cloned,
          cachedAt: DateTime.now(),
        );
        return _cloneItems(cloned);
      }
    }

    if (cacheOnly) return const <SinavModel>[];

    final yanitlarSnap = await _firestore
        .collectionGroup('Yanitlar')
        .where('userID', isEqualTo: normalizedUserId)
        .get();

    final examDocIds = <String>{};
    for (final yanitDoc in yanitlarSnap.docs) {
      final parentRef = yanitDoc.reference.parent.parent;
      if (parentRef != null && parentRef.parent.id == 'practiceExams') {
        examDocIds.add(parentRef.id);
      }
    }

    if (examDocIds.isEmpty) {
      await _store(cacheKey, const <SinavModel>[]);
      return const <SinavModel>[];
    }

    final models = await fetchByIds(
      examDocIds.toList(growable: false),
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    final sorted = models.toList(growable: false)
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    await _store(cacheKey, sorted);
    return sorted;
  }
}
