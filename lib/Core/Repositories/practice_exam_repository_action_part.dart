part of 'practice_exam_repository.dart';

extension PracticeExamRepositoryActionPart on PracticeExamRepository {
  Future<void> _removeCacheKey(String cacheKey) async {
    _memory.remove(cacheKey);
    _boolMemory.remove(cacheKey);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove('$_practiceExamRepositoryPrefsPrefix:$cacheKey');
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

  Future<void> deletePracticeExam(String examId) async {
    final normalizedExamId = examId.trim();
    if (normalizedExamId.isEmpty) return;

    final docRef = _firestore.collection('practiceExams').doc(normalizedExamId);
    final docSnapshot = await docRef.get(
      const GetOptions(source: Source.serverAndCache),
    );
    if (!docSnapshot.exists) return;

    final data = docSnapshot.data() ?? const <String, dynamic>{};
    final ownerUserId = (data['userID'] ?? '').toString().trim();
    final lessons = ((data['dersler'] as List?) ?? const <dynamic>[])
        .map((lesson) => lesson.toString().trim())
        .where((lesson) => lesson.isNotEmpty)
        .toList(growable: false);

    final answersRef = docRef.collection('Yanitlar');
    final answersSnapshot = await answersRef.get(
      const GetOptions(source: Source.serverAndCache),
    );
    final answeredUserIds = <String>{};
    final answerDocIds = <String>[];
    for (final answerDoc in answersSnapshot.docs) {
      final answerId = answerDoc.id.trim();
      if (answerId.isNotEmpty) {
        answerDocIds.add(answerId);
      }
      final answeredUserId =
          (answerDoc.data()['userID'] ?? answerDoc.id).toString().trim();
      if (answeredUserId.isNotEmpty) {
        answeredUserIds.add(answeredUserId);
      }
      for (final lesson in lessons) {
        await _deleteCollectionDocs(answerDoc.reference.collection(lesson));
      }
    }

    final applicationsRef = docRef.collection('Basvurular');
    final applicationsSnapshot = await applicationsRef.get(
      const GetOptions(source: Source.serverAndCache),
    );
    final applicantUserIds = applicationsSnapshot.docs
        .map((doc) => doc.id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();

    await _deleteCollectionDocs(docRef.collection('Sorular'));
    await _deleteCollectionDocs(applicationsRef);
    await _deleteCollectionDocs(answersRef);
    await docRef.delete();

    await Future.wait(<Future<void>>[
      _removeCacheKey('doc:$normalizedExamId'),
      _removeCacheKey('raw:$normalizedExamId'),
      _removeCacheKey('answers:$normalizedExamId'),
      _removeCacheKey('questions:$normalizedExamId'),
    ]);
    for (final applicantUserId in applicantUserIds) {
      await _removeCacheKey('application:$normalizedExamId:$applicantUserId');
    }
    for (final answerDocId in answerDocIds) {
      for (final lesson in lessons) {
        await _removeCacheKey(
          'lesson_result:$normalizedExamId:$answerDocId:$lesson',
        );
      }
    }

    await TypesenseEducationSearchService.instance.invalidateEntity(
      EducationTypesenseEntity.practiceExam,
    );

    final snapshotRepository = maybeFindPracticeExamSnapshotRepository();
    for (final userId in <String>{
      ownerUserId,
      ...answeredUserIds,
      ...applicantUserIds,
    }) {
      if (userId.isEmpty) continue;
      await snapshotRepository?.invalidateUserScopedSurfaces(userId);
    }
    await snapshotRepository?.invalidateAllSurfaces();
  }
}
