part of 'practice_exam_repository.dart';

extension PracticeExamRepositoryDetailPart on PracticeExamRepository {
  Future<bool> hasApplication(
    String examId,
    String userId,
  ) async {
    final normalizedExamId = examId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedExamId.isEmpty || normalizedUserId.isEmpty) return false;
    final cacheKey = 'application:$normalizedExamId:$normalizedUserId';
    final cached = _boolMemory[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            _practiceExamRepositoryTtl) {
      return cached.value;
    }

    final snap = await _firestore
        .collection('practiceExams')
        .doc(normalizedExamId)
        .collection('Basvurular')
        .doc(normalizedUserId)
        .get(const GetOptions(source: Source.serverAndCache));
    _boolMemory[cacheKey] = _TimedPracticeExamBool(
      value: snap.exists,
      cachedAt: DateTime.now(),
    );
    return snap.exists;
  }

  Future<int> fetchParticipantCount(
    String docId, {
    bool preferCache = true,
  }) async {
    final raw = await fetchRawById(docId, preferCache: preferCache);
    final participantCount = raw?['participantCount'];
    if (participantCount is num) {
      return participantCount.toInt();
    }
    final aggregate = await _firestore
        .collection('practiceExams')
        .doc(docId)
        .collection('Basvurular')
        .count()
        .get();
    return aggregate.count ?? 0;
  }

  Future<List<Map<String, dynamic>>> fetchAnswers(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    String? userId,
  }) async {
    final normalizedUserId = userId?.trim() ?? '';
    final cacheKey = normalizedUserId.isEmpty
        ? 'answers:$docId'
        : 'answers:$docId:$normalizedUserId';
    if (!forceRefresh && preferCache) {
      final cached = await _getRawList(cacheKey);
      if (cached != null) return cached;
    }

    final answersRef = _firestore
        .collection('practiceExams')
        .doc(docId)
        .collection('Yanitlar');

    List<Map<String, dynamic>> items;
    if (normalizedUserId.isNotEmpty) {
      final directDoc = await answersRef
          .doc(normalizedUserId)
          .get(const GetOptions(source: Source.serverAndCache));
      if (directDoc.exists) {
        items = <Map<String, dynamic>>[
          <String, dynamic>{
            '_docId': directDoc.id,
            ...?directDoc.data(),
          },
        ];
      } else {
        final snap = await answersRef
            .where('userID', isEqualTo: normalizedUserId)
            .get(const GetOptions(source: Source.serverAndCache));
        items = snap.docs
            .map((doc) => <String, dynamic>{
                  '_docId': doc.id,
                  ...doc.data(),
                })
            .toList(growable: false);
      }
    } else {
      final snap =
          await answersRef.get(const GetOptions(source: Source.serverAndCache));
      items = snap.docs
          .map((doc) => <String, dynamic>{
                '_docId': doc.id,
                ...doc.data(),
              })
          .toList(growable: false);
    }
    await _storeRawList(cacheKey, items);
    return items;
  }

  Future<List<SoruModel>> fetchQuestions(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'questions:$docId';
    if (!forceRefresh && preferCache) {
      final cached = await _getRawList(cacheKey);
      if (cached != null) {
        return cached
            .map(_questionFromMap)
            .whereType<SoruModel>()
            .toList(growable: false);
      }
    }

    final snap = await _firestore
        .collection('practiceExams')
        .doc(docId)
        .collection('Sorular')
        .get();
    final items = snap.docs
        .map((doc) => <String, dynamic>{
              '_docId': doc.id,
              ...doc.data(),
            })
        .toList(growable: false);
    await _storeRawList(cacheKey, items);
    return items
        .map(_questionFromMap)
        .whereType<SoruModel>()
        .toList(growable: false);
  }

  Future<List<DersVeSonuclarDB>> fetchLessonResults(
    String examId,
    String answerId,
    List<String> lessons,
  ) async {
    final results = <DersVeSonuclarDB>[];
    for (final lesson in lessons) {
      final cacheKey = 'lesson_result:$examId:$answerId:$lesson';
      Map<String, dynamic>? data = await _getRawDoc(cacheKey);
      if (data == null) {
        final doc = await _firestore
            .collection('practiceExams')
            .doc(examId)
            .collection('Yanitlar')
            .doc(answerId)
            .collection(lesson)
            .doc(answerId)
            .get();
        if (!doc.exists) continue;
        data = Map<String, dynamic>.from(doc.data() ?? const {});
        await _storeRawDoc(cacheKey, data);
      }
      results.add(
        DersVeSonuclarDB(
          ders: (data['ders'] ?? lesson).toString(),
          dogru: (data['dogru'] ?? 0) as num,
          yanlis: (data['yanlis'] ?? 0) as num,
          bos: (data['bos'] ?? 0) as num,
          net: (data['net'] ?? 0) as num,
        ),
      );
    }
    return results;
  }
}
