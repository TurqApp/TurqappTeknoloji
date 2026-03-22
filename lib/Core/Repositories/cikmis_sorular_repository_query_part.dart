part of 'cikmis_sorular_repository.dart';

extension CikmisSorularRepositoryQueryPart on CikmisSorularRepository {
  Future<List<Map<String, dynamic>>> fetchRootDocs({
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    const cacheKey = 'root_docs';
    if (!forceRefresh && preferCache) {
      final cached = await _readList(cacheKey);
      if (cached != null) return cached;
    }

    if (cacheOnly) return const <Map<String, dynamic>>[];

    final docs = await _fetchRootDocsFromTypesense();
    await _writeList(cacheKey, docs);
    return docs;
  }

  Future<List<CikmisSorularCoverModel>> fetchCovers({
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final docs = await fetchRootDocs(
      preferCache: preferCache,
      forceRefresh: forceRefresh,
      cacheOnly: cacheOnly,
    );
    final seen = <String>{};
    final items = <CikmisSorularCoverModel>[];
    for (final doc in docs) {
      final anaBaslik = (doc['anaBaslik'] ?? '').toString();
      final sinavTuru = (doc['sinavTuru'] ?? '').toString();
      if (anaBaslik.isEmpty || seen.contains(anaBaslik)) continue;
      seen.add(anaBaslik);
      items.add(CikmisSorularCoverModel(
        anaBaslik: anaBaslik,
        docID: (doc['_docId'] ?? '').toString(),
        sinavTuru: sinavTuru,
      ));
    }
    return items;
  }

  Future<List<Map<String, dynamic>>> fetchRootDocsByIds(
    List<String> ids, {
    bool preferCache = true,
  }) async {
    final wanted =
        ids.where((e) => e.trim().isNotEmpty).toList(growable: false);
    if (wanted.isEmpty) return const <Map<String, dynamic>>[];

    final resolved = <String, Map<String, dynamic>>{};
    if (preferCache) {
      final cached = await fetchRootDocs();
      for (final doc in cached) {
        final id = (doc['_docId'] ?? '').toString();
        if (id.isNotEmpty) {
          resolved[id] = Map<String, dynamic>.from(doc);
        }
      }
    }

    final missing = wanted.where((id) => !resolved.containsKey(id)).toList();
    for (var i = 0; i < missing.length; i += 50) {
      final end = (i + 50 > missing.length) ? missing.length : i + 50;
      final chunk = missing.sublist(i, end);
      final result = await TypesenseEducationSearchService.instance.searchHits(
        entity: EducationTypesenseEntity.pastQuestion,
        query: '*',
        limit: chunk.length,
        page: 1,
        filterBy: TypesenseEducationSearchService.filterIn('docId', chunk),
        sortBy: 'seq:asc,timeStamp:desc',
      );
      for (final hit in result.hits) {
        final mapped = _rootDocFromHit(hit);
        final docId = (mapped['_docId'] ?? '').toString();
        if (docId.isNotEmpty) {
          resolved[docId] = mapped;
        }
      }
    }

    return wanted
        .map((id) => resolved[id])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<List<String>> distinctValues({
    required bool Function(Map<String, dynamic> doc) where,
    required String field,
    List<String>? priorityOrder,
    bool descendingNumeric = false,
  }) async {
    final docs = await fetchRootDocs();
    final values = <String>[];
    for (final doc in docs) {
      if (!where(doc)) continue;
      final value = (doc[field] ?? '').toString();
      if (value.isEmpty || values.contains(value)) continue;
      values.add(value);
    }

    if (priorityOrder != null && priorityOrder.isNotEmpty) {
      values.sort((a, b) {
        var ia = priorityOrder.indexOf(a);
        var ib = priorityOrder.indexOf(b);
        if (ia == -1) ia = priorityOrder.length;
        if (ib == -1) ib = priorityOrder.length;
        return ia.compareTo(ib);
      });
      return values;
    }

    if (descendingNumeric) {
      values.sort((a, b) {
        final pa = int.tryParse(a) ?? -1;
        final pb = int.tryParse(b) ?? -1;
        return pb.compareTo(pa);
      });
      return values;
    }

    values.sort();
    return values;
  }

  Future<String?> findQuestionDocId({
    required String anaBaslik,
    required String sinavTuru,
    required String yil,
    required String baslik2,
    required String baslik3,
  }) async {
    final docs = await fetchRootDocs();
    for (final doc in docs) {
      if ((doc['anaBaslik'] ?? '').toString() == anaBaslik &&
          (doc['sinavTuru'] ?? '').toString() == sinavTuru &&
          (doc['yil'] ?? '').toString() == yil &&
          (doc['baslik2'] ?? '').toString() == baslik2 &&
          (doc['baslik3'] ?? '').toString() == baslik3) {
        return (doc['_docId'] ?? '').toString();
      }
    }
    return null;
  }

  Future<List<CikmisSorularinModeli>> fetchQuestionItems(String docId) async {
    final cacheKey = 'questions:$docId';
    final cached = await _readList(cacheKey);
    if (cached != null) {
      return cached.map(_questionItemFromMap).toList(growable: false);
    }

    final fromStorage = await _fetchQuestionsFromStorage(docId);
    if (fromStorage != null) {
      await _writeList(cacheKey, fromStorage);
      return fromStorage.map(_questionItemFromMap).toList(growable: false);
    }

    final baseDoc = _firestore.collection('questions').doc(docId);
    var questionsSnap = await baseDoc
        .collection('questions')
        .get(const GetOptions(source: Source.serverAndCache));
    if (questionsSnap.docs.isEmpty) {
      questionsSnap = await baseDoc
          .collection('Sorular')
          .get(const GetOptions(source: Source.serverAndCache));
    }
    final raw = questionsSnap.docs
        .map((doc) => <String, dynamic>{'_docId': doc.id, ...doc.data()})
        .toList(growable: false);
    await _writeList(cacheKey, raw);
    return raw.map(_questionItemFromMap).toList(growable: false);
  }

  Future<List<CikmisSoruSonucModel>> fetchUserResults(String uid) async {
    final cacheKey = 'results:$uid';
    final cached = await _readList(cacheKey);
    if (cached != null) {
      return cached.map(_resultFromMap).toList(growable: false);
    }
    return const <CikmisSoruSonucModel>[];
  }
}
