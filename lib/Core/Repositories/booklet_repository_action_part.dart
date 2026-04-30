part of 'booklet_repository.dart';

extension BookletRepositoryActionPart on BookletRepository {
  Future<void> _removeCacheKey(String key) async {
    _memory.remove(key);
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
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

  Future<void> saveBooklet(
    String bookletId,
    Map<String, dynamic> data,
  ) async {
    final normalizedBookletId = bookletId.trim();
    if (normalizedBookletId.isEmpty || data.isEmpty) return;
    await _firestore.collection('books').doc(normalizedBookletId).set(
          data,
          SetOptions(merge: true),
        );
    await _removeCacheKey('doc:$normalizedBookletId');
  }

  Future<void> updateBookletCover({
    required String bookletId,
    required String coverUrl,
    required String storagePath,
  }) async {
    final normalizedBookletId = bookletId.trim();
    if (normalizedBookletId.isEmpty) return;
    await _firestore.collection('books').doc(normalizedBookletId).update({
      'cover': coverUrl,
      'coverStoragePath': storagePath,
      'coverFormat': 'webp',
    });
    await _removeCacheKey('doc:$normalizedBookletId');
    await maybeFindAnswerKeySnapshotRepository()?.invalidateAllSurfaces();
  }

  Future<void> incrementViewCount(String bookletId) async {
    final normalizedBookletId = bookletId.trim();
    if (normalizedBookletId.isEmpty) return;
    await _firestore.collection('books').doc(normalizedBookletId).update({
      'viewCount': FieldValue.increment(1),
    });
    await _removeCacheKey('doc:$normalizedBookletId');
  }

  Future<void> saveBookletAnswerResult({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty || data.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('KitapcikCevaplari')
        .add(data);
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
