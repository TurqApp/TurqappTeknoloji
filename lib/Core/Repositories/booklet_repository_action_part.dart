part of 'booklet_repository.dart';

extension BookletRepositoryActionPart on BookletRepository {
  Future<void> _removeCacheKey(String key) async {
    _memory.remove(key);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove('${BookletRepository._prefsPrefix}:$key');
  }

  Future<void> _deleteCollectionDocs(
    CollectionReference<Map<String, dynamic>> collectionRef,
  ) async {
    final snapshot = await collectionRef.get(
      const GetOptions(source: Source.serverAndCache),
    );
    if (snapshot.docs.isEmpty) return;
    for (var i = 0; i < snapshot.docs.length; i += 200) {
      final chunk = snapshot.docs.skip(i).take(200);
      final batch = _firestore.batch();
      for (final doc in chunk) {
        batch.delete(collectionRef.doc(doc.id));
      }
      await batch.commit();
    }
  }

  Future<void> replaceAnswerKeys(
    String bookletId,
    List<Map<String, dynamic>> items,
  ) async {
    final ref = _firestore.collection('books').doc(bookletId);
    final answersRef = ref.collection('CevapAnahtarlari');
    final old = await fetchAnswerKeys(
      bookletId,
      preferCache: false,
      forceRefresh: true,
    );
    final batch = _firestore.batch();
    for (final answer in old) {
      final id = (answer['id'] ?? '').toString();
      if (id.isEmpty) continue;
      batch.delete(answersRef.doc(id));
    }
    final cachedItems = <Map<String, dynamic>>[];
    for (final item in items) {
      final data = Map<String, dynamic>.from(item);
      final docRef = answersRef.doc();
      batch.set(docRef, data);
      cachedItems.add(<String, dynamic>{
        'id': docRef.id,
        'data': data,
      });
    }
    await batch.commit();
    await _storeRawList('answers:$bookletId', cachedItems);
  }

  Future<void> deleteBooklet(String bookletId) async {
    final normalizedBookletId = bookletId.trim();
    if (normalizedBookletId.isEmpty) return;

    final docRef = _firestore.collection('books').doc(normalizedBookletId);
    final docSnapshot = await docRef.get(
      const GetOptions(source: Source.serverAndCache),
    );
    if (!docSnapshot.exists) return;

    final ownerUserId = (docSnapshot.data()?['userID'] ?? '').toString().trim();

    await _deleteCollectionDocs(docRef.collection('CevapAnahtarlari'));
    await docRef.delete();

    await Future.wait(<Future<void>>[
      _removeCacheKey('doc:$normalizedBookletId'),
      _removeCacheKey('answers:$normalizedBookletId'),
    ]);

    await TypesenseEducationSearchService.instance.invalidateEntity(
      EducationTypesenseEntity.answerKey,
    );

    final snapshotRepository = maybeFindAnswerKeySnapshotRepository();
    if (ownerUserId.isNotEmpty) {
      await snapshotRepository?.invalidateUserScopedSurfaces(ownerUserId);
    }
    await snapshotRepository?.invalidateAllSurfaces();
  }
}
