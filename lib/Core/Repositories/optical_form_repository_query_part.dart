part of 'optical_form_repository.dart';

extension OpticalFormRepositoryQueryPart on OpticalFormRepository {
  List<String> _sanitizeStringList(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<OpticalFormModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final key = 'doc:$docId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedMap(key);
      if (cached != null) {
        return OpticalFormModel.fromMap(cached, docId);
      }
    }
    if (cacheOnly) return null;
    final doc = await _firestore.collection('optikForm').doc(docId).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    await _storeMap(key, data);
    return OpticalFormModel.fromMap(data, doc.id);
  }

  Future<List<OpticalFormModel>> fetchByOwner(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final key = 'owner:$userId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(key);
      if (cached != null) {
        return cached
            .map((e) =>
                OpticalFormModel.fromMap(e, (e['docID'] ?? '').toString()))
            .toList(growable: false);
      }
    }

    if (cacheOnly) return const <OpticalFormModel>[];

    final snap = await _firestore
        .collection('optikForm')
        .where('userID', isEqualTo: userId)
        .get(const GetOptions(source: Source.serverAndCache));
    final items = snap.docs
        .map((doc) => OpticalFormModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    await _storePrimitive(
      key,
      items
          .map((e) => <String, dynamic>{
                'docID': e.docID,
                'name': e.name,
                'userID': e.userID,
                'cevaplar': e.cevaplar,
                'max': e.max,
                'baslangic': e.baslangic,
                'bitis': e.bitis,
                'kisitlama': e.kisitlama,
              })
          .toList(growable: false),
    );
    return items;
  }

  Future<List<OpticalFormModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final ids =
        docIds.where((e) => e.trim().isNotEmpty).toList(growable: false);
    if (ids.isEmpty) return const <OpticalFormModel>[];
    final byId = <String, OpticalFormModel>{};
    const chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize > ids.length) ? ids.length : i + chunkSize;
      final chunk = ids.sublist(i, end);
      for (final id in chunk) {
        if (preferCache) {
          final cached = await fetchById(
            id,
            preferCache: true,
            cacheOnly: cacheOnly,
          );
          if (cached != null) byId[id] = cached;
        }
      }
      final missing = chunk.where((id) => !byId.containsKey(id)).toList();
      if (cacheOnly && missing.isNotEmpty) continue;
      if (missing.isEmpty) continue;
      final snap = await _firestore
          .collection('optikForm')
          .where(FieldPath.documentId, whereIn: missing)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snap.docs) {
        final item = OpticalFormModel.fromMap(doc.data(), doc.id);
        byId[doc.id] = item;
        await _storeMap('doc:${doc.id}', doc.data());
      }
    }
    return ids
        .where(byId.containsKey)
        .map((id) => byId[id]!)
        .toList(growable: false);
  }

  Future<List<OpticalFormModel>> fetchAnsweredByUser(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final key = 'answered:$userId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedList(key);
      if (cached != null) {
        return cached
            .map((e) =>
                OpticalFormModel.fromMap(e, (e['docID'] ?? '').toString()))
            .toList(growable: false);
      }
    }

    if (cacheOnly) return const <OpticalFormModel>[];

    final answersSnap = await _firestore
        .collectionGroup('Yanitlar')
        .where(FieldPath.documentId, isEqualTo: userId)
        .get(const GetOptions(source: Source.serverAndCache));
    final formIds = <String>{
      for (final doc in answersSnap.docs)
        if (doc.reference.parent.parent != null &&
            doc.reference.parent.parent!.parent.id == 'optikForm')
          doc.reference.parent.parent!.id,
    }.toList(growable: false);
    final items = await fetchByIds(
      formIds,
      preferCache: true,
      cacheOnly: cacheOnly,
    );
    await _storePrimitive(
      key,
      items
          .map((e) => <String, dynamic>{
                'docID': e.docID,
                'name': e.name,
                'userID': e.userID,
                'cevaplar': e.cevaplar,
                'max': e.max,
                'baslangic': e.baslangic,
                'bitis': e.bitis,
                'kisitlama': e.kisitlama,
              })
          .toList(growable: false),
    );
    return items;
  }

  Future<int> fetchAnswerCount(
    String formId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'count:$formId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedInt(key);
      if (cached != null) return cached;
    }
    final snapshot = await _firestore
        .collection('optikForm')
        .doc(formId)
        .collection('Yanitlar')
        .get();
    final total = snapshot.docs.length;
    await _storePrimitive(key, total);
    return total;
  }

  Future<List<String>> fetchUserAnswers(
    String formId,
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'answers:$formId:$userId';
    if (!forceRefresh && preferCache) {
      final cached = await _getCachedStringList(key);
      if (cached != null) return cached;
    }
    final doc = await _firestore
        .collection('optikForm')
        .doc(formId)
        .collection('Yanitlar')
        .doc(userId)
        .get();
    final answers = _sanitizeStringList(doc.data()?['cevaplar']);
    await _storePrimitive(key, answers);
    return answers;
  }
}
