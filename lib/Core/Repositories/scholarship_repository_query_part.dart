part of 'scholarship_repository.dart';

extension ScholarshipRepositoryQueryPart on ScholarshipRepository {
  Future<IndividualScholarshipsModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final raw = await fetchRawById(
      docId,
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
    if (raw == null) return null;
    return IndividualScholarshipsModel.fromJson(raw);
  }

  Future<Map<String, dynamic>?> fetchRawById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cleanId = docId.trim();
    if (cleanId.isEmpty) return null;
    if (!forceRefresh && preferCache) {
      final memory = _readMemory(cleanId);
      if (memory != null) return memory;
      final disk = await _readPrefs(cleanId);
      if (disk != null) {
        final cloned = _cloneDoc(disk);
        _memory[cleanId] = _TimedScholarship(
          data: cloned,
          cachedAt: DateTime.now(),
        );
        return _cloneDoc(cloned);
      }
    }

    final doc = await ScholarshipFirestorePath.doc(cleanId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    await _store(cleanId, data);
    return data;
  }

  Future<List<Map<String, dynamic>>> fetchMyScholarshipsRaw(
    String uid, {
    int limit = 50,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return const <Map<String, dynamic>>[];
    final cacheKey = 'query:owner:$cleanUid:$limit';

    if (!forceRefresh && preferCache) {
      final memory = _readQueryMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _readQueryPrefs(cacheKey);
      if (disk != null) {
        final cloned = _cloneDocs(disk);
        _queryMemory[cacheKey] = _TimedScholarshipList(
          items: cloned,
          cachedAt: DateTime.now(),
        );
        return _cloneDocs(cloned);
      }
    }

    if (cacheOnly) return const <Map<String, dynamic>>[];

    final snapshot = await ScholarshipFirestorePath.collection()
        .where('userID', isEqualTo: cleanUid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();

    final items = snapshot.docs
        .map((doc) => <String, dynamic>{
              ...Map<String, dynamic>.from(doc.data()),
              'docId': doc.id,
            })
        .toList(growable: false);
    await _storeQueryDocs(cacheKey, items);
    return items;
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchLatestPage({
    int limit = 30,
    DocumentSnapshot? startAfter,
  }) {
    Query<Map<String, dynamic>> query = ScholarshipFirestorePath.collection()
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return query.get();
  }

  Future<List<Map<String, dynamic>>> fetchByIdsRaw(
    List<String> docIds,
  ) async {
    final orderedIds =
        docIds.map((id) => id.trim()).where((id) => id.isNotEmpty).toList();
    if (orderedIds.isEmpty) return const <Map<String, dynamic>>[];

    const chunkSize = 10;
    final byId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    for (var i = 0; i < orderedIds.length; i += chunkSize) {
      final end = (i + chunkSize > orderedIds.length)
          ? orderedIds.length
          : i + chunkSize;
      final chunk = orderedIds.sublist(i, end);
      final snap = await ScholarshipFirestorePath.collection()
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        byId[doc.id] = doc;
      }
    }

    return orderedIds
        .where(byId.containsKey)
        .map((id) => <String, dynamic>{
              ...Map<String, dynamic>.from(byId[id]!.data()),
              'docId': id,
            })
        .toList(growable: false);
  }

  int _asScholarshipCount(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  List<String> _asScholarshipStringList(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  Future<int> fetchTotalCount({
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && preferCache) {
      final cached = await _getRawDoc(_scholarshipRepositoryCountKey);
      final count = _asScholarshipCount(cached?['count']);
      if (count > 0) return count;
    }
    final agg = await ScholarshipFirestorePath.collection().count().get();
    final count = agg.count ?? 0;
    await _storeRawDoc(
      _scholarshipRepositoryCountKey,
      <String, dynamic>{'count': count},
    );
    return count;
  }

  Future<List<Map<String, dynamic>>> fetchAppliedByUserRaw(
    String uid, {
    int limit = 50,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return const <Map<String, dynamic>>[];
    final cacheKey = 'query:applied:$cleanUid:$limit';

    if (!forceRefresh && preferCache) {
      final memory = _readQueryMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _readQueryPrefs(cacheKey);
      if (disk != null) {
        final cloned = _cloneDocs(disk);
        _queryMemory[cacheKey] = _TimedScholarshipList(
          items: cloned,
          cachedAt: DateTime.now(),
        );
        return _cloneDocs(cloned);
      }
    }

    if (cacheOnly) return const <Map<String, dynamic>>[];

    final snapshot = await ScholarshipFirestorePath.collection()
        .where('basvurular', arrayContains: cleanUid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();

    final items = snapshot.docs
        .map((doc) => <String, dynamic>{
              ...Map<String, dynamic>.from(doc.data()),
              'docId': doc.id,
            })
        .toList(growable: false);
    await _storeQueryDocs(cacheKey, items);
    return items;
  }

  Future<List<Map<String, dynamic>>> fetchByArrayMembershipRaw(
    String field,
    String uid, {
    int limit = 50,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cleanUid = uid.trim();
    final cleanField = field.trim();
    if (cleanUid.isEmpty || cleanField.isEmpty) {
      return const <Map<String, dynamic>>[];
    }
    final cacheKey = 'query:membership:$cleanField:$cleanUid:$limit';

    if (!forceRefresh && preferCache) {
      final memory = _readQueryMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _readQueryPrefs(cacheKey);
      if (disk != null) {
        final cloned = _cloneDocs(disk);
        _queryMemory[cacheKey] = _TimedScholarshipList(
          items: cloned,
          cachedAt: DateTime.now(),
        );
        return _cloneDocs(cloned);
      }
    }

    if (cacheOnly) return const <Map<String, dynamic>>[];

    final snapshot = await ScholarshipFirestorePath.collection()
        .where(cleanField, arrayContains: cleanUid)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();

    final items = snapshot.docs
        .map((doc) => <String, dynamic>{
              ...Map<String, dynamic>.from(doc.data()),
              'docId': doc.id,
            })
        .toList(growable: false);
    await _storeQueryDocs(cacheKey, items);
    return items;
  }

  Future<bool> hasUserApplied(
    String scholarshipId,
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cleanScholarshipId = scholarshipId.trim();
    final cleanUserId = userId.trim();
    if (cleanScholarshipId.isEmpty || cleanUserId.isEmpty) return false;
    final key = '$cleanScholarshipId::$cleanUserId';

    if (!forceRefresh && preferCache) {
      final memory = _readApplyMemory(key);
      if (memory != null) return memory;
      final disk = await _readApplyPrefs(key);
      if (disk != null) {
        _applyMemory[key] = _TimedScholarshipApply(
          value: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final docRef = ScholarshipFirestorePath.doc(cleanScholarshipId);
    final doc = await docRef.collection('Basvurular').doc(cleanUserId).get();
    var applied = doc.exists;
    if (!applied) {
      final parentDoc = await docRef.get();
      final applicants = _asScholarshipStringList(
        parentDoc.data()?['basvurular'],
      );
      applied = applicants.contains(cleanUserId);
    }

    await _storeApply(key, applied);
    return applied;
  }

  Future<List<String>> fetchApplicantIds(
    String scholarshipId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cleanId = scholarshipId.trim();
    if (cleanId.isEmpty) return const <String>[];
    final cacheKey = 'applicants:$cleanId';
    if (!forceRefresh && preferCache) {
      final cached = await _getRawDoc(cacheKey);
      if (cached != null) {
        return _asScholarshipStringList(cached['ids']);
      }
    }

    final doc = await ScholarshipFirestorePath.doc(cleanId).get();
    final ids = _asScholarshipStringList(doc.data()?['basvurular']);
    await _storeRawDoc(cacheKey, <String, dynamic>{'ids': ids});
    return ids;
  }

  Future<int> fetchApplicantCount(
    String scholarshipId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final ids = await fetchApplicantIds(
      scholarshipId,
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
    return ids.length;
  }
}
