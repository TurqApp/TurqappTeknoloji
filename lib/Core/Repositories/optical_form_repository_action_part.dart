part of 'optical_form_repository.dart';

extension OpticalFormRepositoryActionPart on OpticalFormRepository {
  Future<void> _removeCacheKey(String key) async {
    _memory.remove(key);
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
    await _prefs?.remove('${OpticalFormRepository._prefsPrefix}:$key');
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

  Future<void> saveForm(
    String formId,
    Map<String, dynamic> data,
  ) async {
    final normalizedFormId = formId.trim();
    if (normalizedFormId.isEmpty || data.isEmpty) return;
    await _firestore.collection('optikForm').doc(normalizedFormId).set(data);
    await _removeCacheKey('doc:$normalizedFormId');
    final ownerUserId = (data['userID'] ?? '').toString().trim();
    final snapshotRepository = maybeFindOpticalFormSnapshotRepository();
    if (ownerUserId.isNotEmpty) {
      await snapshotRepository?.invalidateUserScopedSurfaces(ownerUserId);
    }
    await snapshotRepository?.invalidateAllSurfaces();
  }

  Future<void> initializeUserAnswers(
    String formId,
    String userId,
    int questionCount,
  ) async {
    final normalizedFormId = formId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedFormId.isEmpty || normalizedUserId.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final answers = List<String>.filled(questionCount, '');
    await _firestore
        .collection('optikForm')
        .doc(normalizedFormId)
        .collection('Yanitlar')
        .doc(normalizedUserId)
        .set({
      'timeStamp': now,
      'cevaplar': answers,
    }, SetOptions(merge: true));
    await _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('answered_optical_forms')
        .doc(normalizedFormId)
        .set({
      'opticalFormId': normalizedFormId,
      'updatedDate': now,
      'timeStamp': now,
    }, SetOptions(merge: true));
    await _storePrimitive(
        'answers:$normalizedFormId:$normalizedUserId', answers);
    await maybeFindOpticalFormSnapshotRepository()
        ?.invalidateAnsweredSurface(normalizedUserId);
  }

  Future<void> saveUserAnswers(
    String formId,
    String userId, {
    required List<String> answers,
    required String ogrenciNo,
    required String fullName,
  }) async {
    final normalizedFormId = formId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedFormId.isEmpty || normalizedUserId.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _firestore
        .collection('optikForm')
        .doc(normalizedFormId)
        .collection('Yanitlar')
        .doc(normalizedUserId)
        .update({
      'timeStamp': now,
      'cevaplar': answers,
      'ogrenciNo': ogrenciNo,
      'fullName': fullName,
    });
    await _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('answered_optical_forms')
        .doc(normalizedFormId)
        .set({
      'opticalFormId': normalizedFormId,
      'updatedDate': now,
      'timeStamp': now,
    }, SetOptions(merge: true));
    await _storePrimitive(
        'answers:$normalizedFormId:$normalizedUserId', answers);
    await maybeFindOpticalFormSnapshotRepository()
        ?.invalidateAnsweredSurface(normalizedUserId);
  }

  Future<void> deleteForm(String formId) async {
    final normalizedFormId = formId.trim();
    if (normalizedFormId.isEmpty) return;
    final docRef = _firestore.collection('optikForm').doc(normalizedFormId);
    final docSnapshot = await docRef.get(
      const GetOptions(source: Source.serverAndCache),
    );
    final ownerUserId = (docSnapshot.data()?['userID'] ?? '').toString().trim();
    final answersRef = docRef.collection('Yanitlar');
    final answersSnapshot = await answersRef.get(
      const GetOptions(source: Source.serverAndCache),
    );
    final answeredUserIds = answersSnapshot.docs
        .map((doc) => doc.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    await _deleteCollectionDocs(answersRef);
    await docRef.delete();

    await _removeCacheKey('doc:$normalizedFormId');
    await _removeCacheKey('count:$normalizedFormId');
    for (final userId in answeredUserIds) {
      await _removeCacheKey('answers:$normalizedFormId:$userId');
    }

    final snapshotRepository = maybeFindOpticalFormSnapshotRepository();
    for (final userId in answeredUserIds) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('answered_optical_forms')
          .doc(normalizedFormId)
          .delete()
          .catchError((_) => null);
    }
    for (final userId in <String>{ownerUserId, ...answeredUserIds}) {
      if (userId.isEmpty) continue;
      await snapshotRepository?.invalidateUserScopedSurfaces(userId);
    }
    await snapshotRepository?.invalidateAllSurfaces();
  }
}
