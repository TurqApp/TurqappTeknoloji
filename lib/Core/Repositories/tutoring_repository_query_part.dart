part of 'tutoring_repository.dart';

extension TutoringRepositoryQueryPart on TutoringRepository {
  int _applicationAsInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<TutoringPage> fetchPage({
    DocumentSnapshot? startAfter,
    int limit = 30,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('educators')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap =
        await query.get(const GetOptions(source: Source.serverAndCache));
    final items = snap.docs
        .map((doc) => TutoringModel.fromJson(doc.data(), doc.id))
        .where((t) => !_isExpired(t))
        .toList(growable: false);
    return TutoringPage(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<List<TutoringModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final ids =
        docIds.where((id) => id.trim().isNotEmpty).toList(growable: false);
    if (ids.isEmpty) return const <TutoringModel>[];
    final byId = <String, TutoringModel>{};
    final missing = <String>[];

    if (preferCache) {
      for (final id in ids) {
        final cached = await _getCachedMap('doc:$id');
        if (cached != null) {
          final model = TutoringModel.fromJson(cached, id);
          if (!_isExpired(model)) {
            byId[id] = model;
          }
          continue;
        }
        missing.add(id);
      }
    } else {
      missing.addAll(ids);
    }

    if (cacheOnly) {
      return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
    }

    const chunkSize = 10;
    for (var i = 0; i < missing.length; i += chunkSize) {
      final end =
          (i + chunkSize > missing.length) ? missing.length : i + chunkSize;
      final chunk = missing.sublist(i, end);
      final snapshot = await _firestore
          .collection('educators')
          .where(FieldPath.documentId, whereIn: chunk)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snapshot.docs) {
        final model = TutoringModel.fromJson(doc.data(), doc.id);
        if (_isExpired(model)) continue;
        byId[doc.id] = model;
        await _storeMap('doc:${doc.id}', doc.data());
      }
    }
    return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
  }

  Future<TutoringModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool allowExpired = false,
  }) async {
    final key = 'doc:$docId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedMap(key);
      if (cached != null) {
        final model = TutoringModel.fromJson(cached, docId);
        return !allowExpired && _isExpired(model) ? null : model;
      }
    }
    final doc = await _firestore.collection('educators').doc(docId).get();
    if (!doc.exists || doc.data() == null) return null;
    final data = Map<String, dynamic>.from(doc.data()!);
    await _storeMap(key, data);
    final model = TutoringModel.fromJson(data, doc.id);
    return !allowExpired && _isExpired(model) ? null : model;
  }

  Future<List<TutoringModel>> fetchByOwner(
    String userId, {
    int limit = 100,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'owner:$userId:$limit';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(cacheKey);
      if (cached != null) {
        return cached
            .map(
              (e) => TutoringModel.fromJson(
                Map<String, dynamic>.from((e['data'] as Map?) ?? const {}),
                (e['id'] ?? '').toString(),
              ),
            )
            .toList(growable: false);
      }
    }

    if (cacheOnly) return const <TutoringModel>[];

    final snapshot = await _firestore
        .collection('educators')
        .where('userID', isEqualTo: userId)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => TutoringModel.fromJson(doc.data(), doc.id))
        .toList(growable: false);
    await _storeValue(
      cacheKey,
      snapshot.docs
          .map((doc) => <String, dynamic>{'id': doc.id, 'data': doc.data()})
          .toList(growable: false),
    );
    return items;
  }

  bool _isExpired(TutoringModel model) {
    if (model.ended == true) return true;
    final now = DateTime.now().millisecondsSinceEpoch;
    return now - model.timeStamp > TutoringRepository._thirtyDaysInMillis;
  }

  Future<List<TutoringModel>> fetchByCity(
    String city, {
    int limit = 100,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final normalizedCity = normalizeCityText(city);
    if (normalizedCity.isEmpty) return const <TutoringModel>[];
    final cacheKey = 'city:$normalizedCity';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(cacheKey);
      if (cached != null) {
        return cached
            .map(
              (e) => TutoringModel.fromJson(e, (e['docID'] ?? '').toString()),
            )
            .where((t) => t.docID.isNotEmpty)
            .toList(growable: false);
      }
    }

    final snapshot = await _firestore
        .collection('educators')
        .where('sehir', isEqualTo: city)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snapshot.docs
        .map((doc) => TutoringModel.fromJson(doc.data(), doc.id))
        .toList(growable: false);
    await _storeValue(
      cacheKey,
      snapshot.docs
          .map((doc) => <String, dynamic>{'docID': doc.id, ...doc.data()})
          .toList(growable: false),
    );
    return items;
  }

  Future<bool> hasApplication(String tutoringId, String userId) async {
    final doc = await _firestore
        .collection('educators')
        .doc(tutoringId)
        .collection('Applications')
        .doc(userId)
        .get(const GetOptions(source: Source.serverAndCache));
    return doc.exists;
  }

  Future<List<TutoringModel>> fetchSimilarByBranch(
    String brans,
    String currentDocId, {
    int limit = 11,
  }) async {
    final snapshot = await _firestore
        .collection('educators')
        .where('brans', isEqualTo: brans)
        .limit(limit)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs
        .map((d) => TutoringModel.fromJson(d.data(), d.id))
        .where((t) => t.docID != currentDocId && t.ended != true)
        .take(10)
        .toList(growable: false);
  }

  Future<List<TutoringReviewModel>> fetchReviews(
    String tutoringId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'reviews:$tutoringId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(key);
      if (cached != null) {
        return cached
            .map((e) => TutoringReviewModel.fromMap(
                  Map<String, dynamic>.from((e['data'] as Map?) ?? const {}),
                  (e['id'] ?? '').toString(),
                ))
            .toList(growable: false);
      }
    }
    final snapshot = await _firestore
        .collection('educators')
        .doc(tutoringId)
        .collection('Reviews')
        .orderBy('timeStamp', descending: true)
        .limit(50)
        .get(const GetOptions(source: Source.serverAndCache));
    final raw = snapshot.docs
        .map((d) => <String, dynamic>{'id': d.id, 'data': d.data()})
        .toList(growable: false);
    await _storeValue(key, raw);
    return snapshot.docs
        .map((d) => TutoringReviewModel.fromMap(d.data(), d.id))
        .toList(growable: false);
  }

  Future<List<TutoringApplicationModel>> fetchApplications(
    String tutoringId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'applications:$tutoringId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(key);
      if (cached != null) {
        return cached
            .map((e) => TutoringApplicationModel(
                  tutoringDocID: tutoringId,
                  userID: (e['userID'] ?? e['_docId'] ?? '').toString(),
                  tutoringTitle: (e['tutoringTitle'] ?? '').toString(),
                  tutorName: (e['tutorName'] ?? '').toString(),
                  tutorImage: (e['tutorImage'] ?? '').toString(),
                  status: (e['status'] ?? 'pending').toString(),
                  timeStamp: _applicationAsInt(e['timeStamp']),
                  statusUpdatedAt: _applicationAsInt(e['statusUpdatedAt']),
                  note: (e['note'] ?? '').toString(),
                ))
            .toList(growable: false);
      }
    }

    final snapshot = await _firestore
        .collection('educators')
        .doc(tutoringId)
        .collection('Applications')
        .orderBy('timeStamp', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));
    final raw = snapshot.docs
        .map((doc) => <String, dynamic>{'_docId': doc.id, ...doc.data()})
        .toList(growable: false);
    await _storeValue(key, raw);
    return raw
        .map((e) => TutoringApplicationModel(
              tutoringDocID: tutoringId,
              userID: (e['_docId'] ?? '').toString(),
              tutoringTitle: (e['tutoringTitle'] ?? '').toString(),
              tutorName: (e['tutorName'] ?? '').toString(),
              tutorImage: (e['tutorImage'] ?? '').toString(),
              status: (e['status'] ?? 'pending').toString(),
              timeStamp: _applicationAsInt(e['timeStamp']),
              statusUpdatedAt: _applicationAsInt(e['statusUpdatedAt']),
              note: (e['note'] ?? '').toString(),
            ))
        .toList(growable: false);
  }
}
