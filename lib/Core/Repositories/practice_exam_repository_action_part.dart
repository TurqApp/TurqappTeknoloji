part of 'practice_exam_repository.dart';

extension PracticeExamRepositoryActionPart on PracticeExamRepository {
  Future<void> _removeCacheKey(String cacheKey) async {
    _memory.remove(cacheKey);
    _boolMemory.remove(cacheKey);
    _prefs ??= await ensureLocalPreferenceRepository().sharedPreferences();
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

  Future<void> savePracticeExam({
    required String examId,
    required Map<String, dynamic> data,
  }) async {
    final normalizedExamId = examId.trim();
    if (normalizedExamId.isEmpty || data.isEmpty) return;
    await _firestore.collection('practiceExams').doc(normalizedExamId).set(
          data,
          SetOptions(merge: true),
        );
  }

  Future<void> updatePracticeExamCover({
    required String examId,
    required String coverUrl,
  }) async {
    final normalizedExamId = examId.trim();
    if (normalizedExamId.isEmpty) return;
    await _firestore.collection('practiceExams').doc(normalizedExamId).update({
      'cover': coverUrl,
    });
  }

  Future<void> createQuestionDrafts({
    required String examId,
    required List<String> lessons,
    required List<int> questionCounts,
  }) async {
    final normalizedExamId = examId.trim();
    if (normalizedExamId.isEmpty || lessons.isEmpty) return;
    final questionsRef = _firestore
        .collection('practiceExams')
        .doc(normalizedExamId)
        .collection('Sorular');

    for (var lessonIndex = 0; lessonIndex < lessons.length; lessonIndex++) {
      final lesson = lessons[lessonIndex];
      final questionCount =
          lessonIndex < questionCounts.length ? questionCounts[lessonIndex] : 0;
      for (var questionIndex = 0;
          questionIndex < questionCount;
          questionIndex++) {
        await questionsRef
            .doc(DateTime.now().microsecondsSinceEpoch.toString())
            .set({
          'id': questionIndex,
          'soru': '',
          'ders': lesson,
          'konu': '',
          'dogruCevap': 'A',
          'yanitlayanlar': [],
        });
      }
    }
  }

  Future<void> saveQuestion({
    required String examId,
    required String questionId,
    required Map<String, dynamic> data,
  }) async {
    final normalizedExamId = examId.trim();
    final normalizedQuestionId = questionId.trim();
    if (normalizedExamId.isEmpty ||
        normalizedQuestionId.isEmpty ||
        data.isEmpty) {
      return;
    }
    await _firestore
        .collection('practiceExams')
        .doc(normalizedExamId)
        .collection('Sorular')
        .doc(normalizedQuestionId)
        .set(data, SetOptions(merge: true));
  }

  Future<void> publishPracticeExam(String examId) async {
    final normalizedExamId = examId.trim();
    if (normalizedExamId.isEmpty) return;
    await _firestore.collection('practiceExams').doc(normalizedExamId).set(
      {'taslak': false},
      SetOptions(merge: true),
    );
  }

  Future<void> markExamCompleted({
    required String examId,
    required String userId,
  }) async {
    final normalizedExamId = examId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedExamId.isEmpty || normalizedUserId.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _firestore
        .collection('practiceExams')
        .doc(normalizedExamId)
        .collection('SinaviBitenler')
        .doc(now.toString())
        .set({
      'userID': normalizedUserId,
      'timeStamp': now,
    });
  }

  Future<bool> applyToPracticeExam({
    required String examId,
    required String userId,
  }) async {
    final normalizedExamId = examId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedExamId.isEmpty || normalizedUserId.isEmpty) return false;
    final examRef = _firestore.collection('practiceExams').doc(
          normalizedExamId,
        );
    final applicationRef = examRef.collection('Basvurular').doc(
          normalizedUserId,
        );
    var alreadyApplied = false;

    await _firestore.runTransaction((transaction) async {
      final applicationDoc = await transaction.get(applicationRef);
      if (applicationDoc.exists) {
        alreadyApplied = true;
        return;
      }

      final examDoc = await transaction.get(examRef);
      final currentCount = ((examDoc.data() ??
              const <String, dynamic>{})['participantCount'] as num?) ??
          0;

      transaction.set(applicationRef, {
        'userID': normalizedUserId,
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
      });
      transaction.update(examRef, {
        'participantCount': currentCount.toInt() + 1,
      });
    });

    return alreadyApplied;
  }

  Future<void> markExamInvalid({
    required String examId,
    required String userId,
  }) async {
    final normalizedExamId = examId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedExamId.isEmpty || normalizedUserId.isEmpty) return;
    await _firestore.collection('practiceExams').doc(normalizedExamId).set({
      'gecersizSayilanlar': FieldValue.arrayUnion([normalizedUserId]),
    }, SetOptions(merge: true));
  }

  Future<void> saveAnswerSession({
    required String examId,
    required String answerDocId,
    required String userId,
    required List<String> answers,
    required List<DersVeSonuclar> lessonResults,
    required int timeStamp,
  }) async {
    final normalizedExamId = examId.trim();
    final normalizedAnswerDocId = answerDocId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedExamId.isEmpty ||
        normalizedAnswerDocId.isEmpty ||
        normalizedUserId.isEmpty) {
      return;
    }
    final answerRef = _firestore
        .collection('practiceExams')
        .doc(normalizedExamId)
        .collection('Yanitlar')
        .doc(normalizedAnswerDocId);
    await answerRef.set({
      'yanitlar': answers,
      'userID': normalizedUserId,
      'timeStamp': timeStamp,
    });

    for (final result in lessonResults) {
      await answerRef.collection(result.ders).doc(normalizedAnswerDocId).set({
        'bos': result.bos,
        'yanlis': result.yanlis,
        'dogru': result.dogru,
        'ders': result.ders,
        'net': result.dogru - (0.25 * result.yanlis),
      });
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

    if (answeredUserIds.isNotEmpty) {
      final answeredUserIdList =
          answeredUserIds.where((id) => id.isNotEmpty).toList(growable: false);
      for (var index = 0; index < answeredUserIdList.length; index += 200) {
        final batch = _firestore.batch();
        final chunk = answeredUserIdList.skip(index).take(200);
        for (final answeredUserId in chunk) {
          batch.delete(
            _firestore
                .collection('users')
                .doc(answeredUserId)
                .collection('answered_practice_exams')
                .doc(normalizedExamId),
          );
        }
        await batch.commit();
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
