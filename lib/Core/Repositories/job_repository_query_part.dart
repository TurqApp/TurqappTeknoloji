part of 'job_repository.dart';

extension JobRepositoryQueryPart on JobRepository {
  int _applicationAsInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final normalized = value.trim();
      final parsed = int.tryParse(normalized);
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(normalized);
      if (parsedNum != null) return parsedNum.toInt();
    }
    return 0;
  }

  Future<JobModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'doc:$docId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null && memory.isNotEmpty) return memory.first;
      final disk = await _getFromPrefsEntry(cacheKey);
      if (disk != null && disk.items.isNotEmpty) {
        final cloned = _cloneJobs(disk.items);
        _memory[cacheKey] = _TimedJobs(
          items: cloned,
          cachedAt: disk.cachedAt,
        );
        return _cloneJob(cloned.first);
      }
    }

    if (cacheOnly) return null;

    final doc =
        await _firestore.collection(JobCollection.name).doc(docId).get();
    if (!doc.exists) return null;
    final item = JobModel.fromMap(doc.data() ?? const {}, doc.id);
    await _store(cacheKey, <JobModel>[item]);
    return item;
  }

  Future<List<JobModel>> fetchLatestJobs({
    int limit = ReadBudgetRegistry.jobHomeInitialLimit,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'latest:$limit';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefsEntry(cacheKey);
      if (disk != null) {
        final cloned = _cloneJobs(disk.items);
        _memory[cacheKey] = _TimedJobs(
          items: cloned,
          cachedAt: disk.cachedAt,
        );
        return _cloneJobs(cloned);
      }
    }

    final snapshot = await _firestore
        .collection(JobCollection.name)
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => JobModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<JobModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final ids = docIds.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <JobModel>[];

    final resolved = <String, JobModel>{};
    final missing = <String>[];

    if (preferCache) {
      for (final id in ids) {
        final memory = _getFromMemory('doc:$id');
        if (memory != null && memory.isNotEmpty) {
          resolved[id] = memory.first;
          continue;
        }
        final disk = await _getFromPrefsEntry('doc:$id');
        if (disk != null && disk.items.isNotEmpty) {
          final cloned = _cloneJobs(disk.items);
          _memory['doc:$id'] = _TimedJobs(
            items: cloned,
            cachedAt: disk.cachedAt,
          );
          resolved[id] = _cloneJob(cloned.first);
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
          .whereType<JobModel>()
          .toList(growable: false);
    }

    for (final chunk in _chunkIds(missing, 10)) {
      final snap = await _firestore
          .collection(JobCollection.name)
          .where(FieldPath.documentId, whereIn: chunk)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snap.docs) {
        final item = JobModel.fromMap(doc.data(), doc.id);
        resolved[doc.id] = item;
        await _store('doc:${doc.id}', <JobModel>[item]);
      }
    }

    return ids
        .map((id) => resolved[id])
        .whereType<JobModel>()
        .toList(growable: false);
  }

  Future<List<JobModel>> fetchSimilarByProfession(
    String meslek, {
    int limit = 15,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final normalized = normalizeSearchText(meslek);
    final cacheKey = 'profession:$normalized:$limit';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefsEntry(cacheKey);
      if (disk != null) {
        final cloned = _cloneJobs(disk.items);
        _memory[cacheKey] = _TimedJobs(
          items: cloned,
          cachedAt: disk.cachedAt,
        );
        return _cloneJobs(cloned);
      }
    }

    final snapshot = await _firestore
        .collection(JobCollection.name)
        .where('meslek', isEqualTo: meslek)
        .where('ended', isEqualTo: false)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => JobModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<bool> hasApplication(
    String jobDocId,
    String uid,
  ) async {
    final cacheKey = 'application:$jobDocId:$uid';
    final cached = _boolMemory[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= JobRepository._ttl) {
      return cached.value;
    }

    final snap = await _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .collection('Applications')
        .doc(uid)
        .get(const GetOptions(source: Source.serverAndCache));
    _boolMemory[cacheKey] = _TimedBool(
      value: snap.exists,
      cachedAt: DateTime.now(),
    );
    return snap.exists;
  }

  Future<List<JobApplicationModel>> fetchApplications(
    String jobDocId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'applications:$jobDocId';
    if (!forceRefresh && preferCache) {
      final raw = await _readList(cacheKey);
      if (raw != null) {
        return raw
            .map((data) => JobApplicationModel(
                  jobDocID: jobDocId,
                  userID: (data['_docId'] ?? '').toString(),
                  jobTitle: (data['jobTitle'] ?? '').toString(),
                  companyName: (data['companyName'] ?? '').toString(),
                  companyLogo: (data['companyLogo'] ?? '').toString(),
                  applicantName: (data['applicantName'] ?? '').toString(),
                  applicantNickname:
                      (data['applicantNickname'] ?? '').toString(),
                  applicantPfImage: (data['applicantPfImage'] ?? '').toString(),
                  status: (data['status'] ?? 'pending').toString(),
                  timeStamp: _applicationAsInt(data['timeStamp']),
                  statusUpdatedAt: _applicationAsInt(data['statusUpdatedAt']),
                  note: (data['note'] ?? '').toString(),
                ))
            .toList(growable: false);
      }
    }

    if (cacheOnly) return const <JobApplicationModel>[];

    final snapshot = await _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .collection('Applications')
        .orderBy('timeStamp', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));
    final raw = snapshot.docs
        .map((doc) => <String, dynamic>{'_docId': doc.id, ...doc.data()})
        .toList(growable: false);
    await _writeList(cacheKey, raw);
    return raw
        .map((data) => JobApplicationModel(
              jobDocID: jobDocId,
              userID: (data['_docId'] ?? '').toString(),
              jobTitle: (data['jobTitle'] ?? '').toString(),
              companyName: (data['companyName'] ?? '').toString(),
              companyLogo: (data['companyLogo'] ?? '').toString(),
              applicantName: (data['applicantName'] ?? '').toString(),
              applicantNickname: (data['applicantNickname'] ?? '').toString(),
              applicantPfImage: (data['applicantPfImage'] ?? '').toString(),
              status: (data['status'] ?? 'pending').toString(),
              timeStamp: _applicationAsInt(data['timeStamp']),
              statusUpdatedAt: _applicationAsInt(data['statusUpdatedAt']),
              note: (data['note'] ?? '').toString(),
            ))
        .toList(growable: false);
  }

  Future<List<JobReviewModel>> fetchReviews(
    String jobDocId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'reviews:$jobDocId';
    if (!forceRefresh && preferCache) {
      final raw = await _readList(cacheKey);
      if (raw != null) {
        return raw
            .map((data) => JobReviewModel.fromMap(
                  Map<String, dynamic>.from(data),
                  (data['_docId'] ?? '').toString(),
                ))
            .toList(growable: false);
      }
    }

    if (cacheOnly) return const <JobReviewModel>[];

    final snapshot = await _firestore
        .collection(JobCollection.name)
        .doc(jobDocId)
        .collection('Reviews')
        .orderBy('timeStamp', descending: true)
        .limit(50)
        .get(const GetOptions(source: Source.serverAndCache));
    final raw = snapshot.docs
        .map((doc) => <String, dynamic>{'_docId': doc.id, ...doc.data()})
        .toList(growable: false);
    await _writeList(cacheKey, raw);
    return raw
        .map((data) => JobReviewModel.fromMap(
              Map<String, dynamic>.from(data),
              (data['_docId'] ?? '').toString(),
            ))
        .toList(growable: false);
  }
}
