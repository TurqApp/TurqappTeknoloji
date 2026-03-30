part of 'optical_form_repository.dart';

extension OpticalFormRepositoryActionPart on OpticalFormRepository {
  Future<void> _removeCacheKey(String key) async {
    _memory.remove(key);
    _prefs ??= await SharedPreferences.getInstance();
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

  Future<void> initializeUserAnswers(
    String formId,
    String userId,
    int questionCount,
  ) async {
    final answers = List<String>.filled(questionCount, '');
    await _firestore
        .collection('optikForm')
        .doc(formId)
        .collection('Yanitlar')
        .doc(userId)
        .set({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'cevaplar': answers,
    }, SetOptions(merge: true));
    await _storePrimitive('answers:$formId:$userId', answers);
  }

  Future<void> saveUserAnswers(
    String formId,
    String userId, {
    required List<String> answers,
    required String ogrenciNo,
    required String fullName,
  }) async {
    await _firestore
        .collection('optikForm')
        .doc(formId)
        .collection('Yanitlar')
        .doc(userId)
        .update({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'cevaplar': answers,
      'ogrenciNo': ogrenciNo,
      'fullName': fullName,
    });
    await _storePrimitive('answers:$formId:$userId', answers);
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
    for (final userId in <String>{ownerUserId, ...answeredUserIds}) {
      if (userId.isEmpty) continue;
      await snapshotRepository?.invalidateUserScopedSurfaces(userId);
    }
    await snapshotRepository?.invalidateAllSurfaces();
  }
}
