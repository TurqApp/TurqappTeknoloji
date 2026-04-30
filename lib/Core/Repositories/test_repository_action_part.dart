part of 'test_repository_parts.dart';

extension TestRepositoryActionPart on TestRepository {
  List<String> _sanitizeStringList(dynamic raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((item) => item?.toString().trim() ?? '')
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _deleteCollectionDocs(
    CollectionReference<Map<String, dynamic>> collectionRef,
  ) async {
    final snapshot = await collectionRef.get(
      const GetOptions(source: Source.serverAndCache),
    );
    if (snapshot.docs.isEmpty) return;
    for (final chunk in _chunkIds(
      snapshot.docs.map((doc) => doc.id).toList(growable: false),
      200,
    )) {
      final batch = _firestore.batch();
      for (final docId in chunk) {
        batch.delete(collectionRef.doc(docId));
      }
      await batch.commit();
    }
  }

  Future<void> setTestImage({
    required String testId,
    required String imageUrl,
  }) async {
    if (!legacyTestsNetworkEnabled) return;
    final normalizedTestId = testId.trim();
    if (normalizedTestId.isEmpty) return;
    await _firestore.collection('Testler').doc(normalizedTestId).set(
      {'img': imageUrl},
      SetOptions(merge: true),
    );
    await _removeCacheKey('doc:$normalizedTestId');
    await _removeCacheKey('raw:$normalizedTestId');
  }

  Future<void> updateTestDetails({
    required String testId,
    required Map<String, dynamic> data,
  }) async {
    if (!legacyTestsNetworkEnabled) return;
    final normalizedTestId = testId.trim();
    if (normalizedTestId.isEmpty || data.isEmpty) return;
    await _firestore.collection('Testler').doc(normalizedTestId).update(data);
    await _removeCacheKey('doc:$normalizedTestId');
    await _removeCacheKey('raw:$normalizedTestId');
    await maybeFindTestSnapshotRepository()?.invalidateAllSurfaces();
  }

  Future<void> prepareDraftTest({
    required String testId,
    required Map<String, dynamic> data,
  }) async {
    if (!legacyTestsNetworkEnabled) return;
    final normalizedTestId = testId.trim();
    if (normalizedTestId.isEmpty || data.isEmpty) return;
    await _firestore.collection('Testler').doc(normalizedTestId).set(
          data,
          SetOptions(merge: true),
        );
    await _removeCacheKey('doc:$normalizedTestId');
    await _removeCacheKey('raw:$normalizedTestId');
    await maybeFindTestSnapshotRepository()?.invalidateAllSurfaces();
  }

  Future<void> saveQuestion({
    required String testId,
    required String questionId,
    required Map<String, dynamic> data,
  }) async {
    if (!legacyTestsNetworkEnabled) return;
    final normalizedTestId = testId.trim();
    final normalizedQuestionId = questionId.trim();
    if (normalizedTestId.isEmpty ||
        normalizedQuestionId.isEmpty ||
        data.isEmpty) {
      return;
    }
    await _firestore
        .collection('Testler')
        .doc(normalizedTestId)
        .collection('Sorular')
        .doc(normalizedQuestionId)
        .set(data, SetOptions(merge: true));
    await _removeCacheKey('questions:$normalizedTestId');
  }

  Future<void> setQuestionCorrectAnswer({
    required String testId,
    required String questionId,
    required String correctAnswer,
  }) {
    return saveQuestion(
      testId: testId,
      questionId: questionId,
      data: {'dogruCevap': correctAnswer},
    );
  }

  Future<void> publishTest(String testId) async {
    if (!legacyTestsNetworkEnabled) return;
    final normalizedTestId = testId.trim();
    if (normalizedTestId.isEmpty) return;
    await _firestore.collection('Testler').doc(normalizedTestId).set(
      {'taslak': false},
      SetOptions(merge: true),
    );
    await _removeCacheKey('doc:$normalizedTestId');
    await _removeCacheKey('raw:$normalizedTestId');
    await maybeFindTestSnapshotRepository()?.invalidateAllSurfaces();
  }

  Future<void> submitAnswers(
    String testId, {
    required String userId,
    required List<String> answers,
  }) async {
    if (!legacyTestsNetworkEnabled) return;
    final normalizedTestId = testId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedTestId.isEmpty || normalizedUserId.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final answerDocId = now.toString();
    await _firestore
        .collection('Testler')
        .doc(normalizedTestId)
        .collection('Yanitlar')
        .doc(answerDocId)
        .set({
      'cevaplar': answers,
      'timeStamp': now,
      'userID': normalizedUserId,
    });
    await _firestore
        .collection('users')
        .doc(normalizedUserId)
        .collection('answered_tests')
        .doc(normalizedTestId)
        .set({
      'testId': normalizedTestId,
      'answerDocId': answerDocId,
      'updatedDate': now,
      'timeStamp': now,
    }, SetOptions(merge: true));
    _memory.remove('answers:$normalizedTestId');
    await maybeFindTestSnapshotRepository()
        ?.invalidateAnsweredSurface(normalizedUserId);
  }

  Future<void> deleteQuestion({
    required String testId,
    required String questionId,
  }) async {
    if (!legacyTestsNetworkEnabled) return;
    final normalizedTestId = testId.trim();
    final normalizedQuestionId = questionId.trim();
    if (normalizedTestId.isEmpty || normalizedQuestionId.isEmpty) return;
    await _firestore
        .collection('Testler')
        .doc(normalizedTestId)
        .collection('Sorular')
        .doc(normalizedQuestionId)
        .delete();
    await _removeCacheKey('questions:$normalizedTestId');
  }

  Future<bool> toggleFavorite(
    String testId, {
    required String userId,
  }) async {
    if (!legacyTestsNetworkEnabled) return false;
    final docRef = _firestore.collection('Testler').doc(testId);
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return false;

    final favorites = _sanitizeStringList(docSnapshot.data()?['favoriler']);
    final isFavorite = favorites.contains(userId);
    await docRef.update({
      'favoriler': isFavorite
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });

    final updated = Map<String, dynamic>.from(docSnapshot.data() ?? const {})
      ..['favoriler'] = isFavorite
          ? favorites.where((e) => e != userId).toList(growable: false)
          : <String>[...favorites, userId];
    await _storeRawDoc('raw:$testId', updated);
    return !isFavorite;
  }

  Future<void> deleteTest(String testId) async {
    if (!legacyTestsNetworkEnabled) return;
    final normalizedTestId = testId.trim();
    if (normalizedTestId.isEmpty) return;
    final docRef = _firestore.collection('Testler').doc(normalizedTestId);
    final docSnapshot = await docRef.get(
      const GetOptions(source: Source.serverAndCache),
    );
    if (!docSnapshot.exists) return;

    final answersRef = docRef.collection('Yanitlar');
    final answersSnapshot = await answersRef.get(
      const GetOptions(source: Source.serverAndCache),
    );
    final answeredUserIds = answersSnapshot.docs
        .map((doc) => (doc.data()['userID'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    final favoritedUserIds =
        _sanitizeStringList(docSnapshot.data()?['favoriler']).toSet();

    await _deleteCollectionDocs(docRef.collection('Sorular'));
    await _deleteCollectionDocs(answersRef);
    await docRef.delete();

    await Future.wait(<Future<void>>[
      _removeCacheKey('doc:$normalizedTestId'),
      _removeCacheKey('raw:$normalizedTestId'),
      _removeCacheKey('answers:$normalizedTestId'),
      _removeCacheKey('questions:$normalizedTestId'),
    ]);

    for (final userId in answeredUserIds) {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('answered_tests')
          .doc(normalizedTestId)
          .delete()
          .catchError((_) => null);
    }

    for (final userId in <String>{
      ...answeredUserIds,
      ...favoritedUserIds,
    }) {
      await maybeFindTestSnapshotRepository()?.invalidateUserScopedSurfaces(
        userId,
      );
    }
    await maybeFindTestSnapshotRepository()?.invalidateAllSurfaces();
  }
}
