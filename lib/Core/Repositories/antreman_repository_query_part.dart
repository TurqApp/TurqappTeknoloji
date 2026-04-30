part of 'antreman_repository.dart';

extension AntremanRepositoryQueryPart on AntremanRepository {
  Stream<int?> scoreStream(String userId, {DateTime? now}) async* {
    if (userId.isEmpty) {
      yield null;
      return;
    }
    final prefs = await ensureLocalPreferenceRepository().sharedPreferences();
    yield prefs.getInt(_localScorePrefsKey(userId, now: now));
  }

  Stream<int> commentCountStream(String questionId) {
    if (questionId.isEmpty) {
      return Stream<int>.value(0);
    }
    return Stream<int>.value(_commentsCache[questionId]?.length ?? 0);
  }

  Future<int?> getMonthlyScore(String userId, {DateTime? now}) async {
    if (userId.isEmpty) return null;
    final prefs = await ensureLocalPreferenceRepository().sharedPreferences();
    return prefs.getInt(_localScorePrefsKey(userId, now: now));
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboardPage({
    required String monthKey,
    required int pageSize,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(AntremanRepository._scoreCollection)
        .doc(monthKey)
        .collection('items')
        .orderBy('antPoint', descending: true)
        .limit(pageSize);
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) =>
            <String, dynamic>{...doc.data(), 'userID': doc.id, '_doc': doc})
        .toList(growable: false);
  }

  Future<List<QuestionBankModel>> fetchCategoryQuestions(
    String anaBaslik,
    String sinavTuru,
    String ders, {
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('questionBank')
        .where('anaBaslik', isEqualTo: anaBaslik)
        .where('sinavTuru', isEqualTo: sinavTuru)
        .where('ders', isEqualTo: ders);
    if (limit != null) {
      query = query.limit(limit);
    }
    final snapshot = await query.get();
    final models = <QuestionBankModel>[];
    for (final doc in snapshot.docs) {
      final data = Map<String, dynamic>.from(doc.data());
      data['docID'] = doc.id;
      data['categoryKey'] =
          data['categoryKey'] ?? '$anaBaslik|$sinavTuru|$ders';
      data['active'] = data['active'] ?? true;
      if (data['active'] == false) continue;
      models.add(QuestionBankModel.fromJson(data));
    }
    models.sort((a, b) {
      if (a.seq != b.seq) return a.seq.compareTo(b.seq);
      return a.soruNo.compareTo(b.soruNo);
    });
    return models;
  }

  Future<Map<String, List<String>>> fetchUniqueFields({
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final now = DateTime.now();
    final hasFreshCache = _uniqueFieldsCache != null &&
        _uniqueFieldsCachedAt != null &&
        now.difference(_uniqueFieldsCachedAt!) <=
            AntremanRepository._uniqueFieldsTtl;
    if (!forceRefresh && preferCache && hasFreshCache) {
      return {
        'anaBaslik':
            List<String>.from(_uniqueFieldsCache!['anaBaslik'] ?? const []),
        'ders': List<String>.from(_uniqueFieldsCache!['ders'] ?? const []),
        'sinavTuru':
            List<String>.from(_uniqueFieldsCache!['sinavTuru'] ?? const []),
      };
    }

    final anaBaslikSet = <String>{};
    final dersSet = <String>{};
    final sinavTuruSet = <String>{};
    final querySnapshot = await _firestore.collection('questionBank').get();

    for (final doc in querySnapshot.docs) {
      final data = doc.data();
      final anaBaslik = data['anaBaslik']?.toString().trim() ?? '';
      final ders = data['ders']?.toString().trim() ?? '';
      final sinavTuru = data['sinavTuru']?.toString().trim() ?? '';
      if (anaBaslik.isNotEmpty) anaBaslikSet.add(anaBaslik);
      if (ders.isNotEmpty) dersSet.add(ders);
      if (sinavTuru.isNotEmpty) sinavTuruSet.add(sinavTuru);
    }

    final payload = <String, List<String>>{
      'anaBaslik': anaBaslikSet.toList(growable: false),
      'ders': dersSet.toList(growable: false),
      'sinavTuru': sinavTuruSet.toList(growable: false),
    };
    _uniqueFieldsCache = payload;
    _uniqueFieldsCachedAt = now;
    return {
      'anaBaslik': List<String>.from(payload['anaBaslik']!),
      'ders': List<String>.from(payload['ders']!),
      'sinavTuru': List<String>.from(payload['sinavTuru']!),
    };
  }

  Future<List<String>> fetchSavedQuestionIds(
    String userId, {
    int limit = ReadBudgetRegistry.antremanSavedQuestionInitialLimit,
  }) async {
    if (userId.isEmpty) return const <String>[];
    final savedMap = await _readPrefsJsonMap(_localSavedPrefsKey(userId));
    final entries = savedMap.entries
        .map(
            (entry) => MapEntry(entry.key, (entry.value as num?)?.toInt() ?? 0))
        .toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(limit)
        .map((entry) => entry.key)
        .toList(growable: false);
  }

  Future<Map<String, String>> fetchUserAnswers(
    String userId,
    List<String> docIds,
  ) async {
    return const <String, String>{};
  }

  Future<Set<String>> fetchAnsweredIds(
      String userId, List<String> docIds) async {
    final out = <String>{};
    if (userId.isEmpty || docIds.isEmpty) return out;
    final answered = await _readPrefsJsonMap(_localAnswersPrefsKey(userId));
    for (final docId in docIds) {
      if (answered.containsKey(docId)) {
        out.add(docId);
      }
    }
    return out;
  }

  Future<Set<String>> fetchSavedIds(String userId, List<String> docIds) async {
    final out = <String>{};
    if (userId.isEmpty || docIds.isEmpty) return out;
    final savedMap = await _readPrefsJsonMap(_localSavedPrefsKey(userId));
    for (final docId in docIds) {
      if (savedMap.containsKey(docId)) {
        out.add(docId);
      }
    }
    return out;
  }

  Future<List<QuestionBankModel>> fetchQuestionModelsByIds(
    List<String> ids,
  ) async {
    final byId = <String, QuestionBankModel>{};
    if (ids.isEmpty) return const <QuestionBankModel>[];
    for (int i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, (i + 10) > ids.length ? ids.length : i + 10);
      final snap = await _firestore
          .collection('questionBank')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        data['docID'] = doc.id;
        byId[doc.id] = QuestionBankModel.fromJson(data);
      }
    }
    return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
  }

  Future<Map<String, dynamic>?> getProgress(
    String userId,
    String categoryKey,
  ) async {
    if (userId.isEmpty || categoryKey.isEmpty) return null;
    final data =
        await _readPrefsJsonMap(_localProgressPrefsKey(userId, categoryKey));
    if (data.isEmpty) return null;
    return data;
  }

  Future<List<Comment>> fetchComments(String questionId) async {
    if (_commentsCache.containsKey(questionId)) {
      return List<Comment>.from(_commentsCache[questionId]!);
    }
    final snapshot = await _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .orderBy('timeStamp', descending: true)
        .get();

    final comments = snapshot.docs
        .map((doc) => Comment.fromJson(doc.id, doc.data()))
        .toList();
    _commentsCache[questionId] = comments;
    return List<Comment>.from(comments);
  }

  Future<List<Reply>> fetchReplies(
    String questionId,
    String commentDocId,
  ) async {
    final cacheKey = '$questionId::$commentDocId';
    if (_repliesCache.containsKey(cacheKey)) {
      return List<Reply>.from(_repliesCache[cacheKey]!);
    }
    final snapshot = await _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .doc(commentDocId)
        .collection('Yanitlar')
        .orderBy('timeStamp', descending: true)
        .get();

    final replies =
        snapshot.docs.map((doc) => Reply.fromJson(doc.id, doc.data())).toList();
    _repliesCache[cacheKey] = replies;
    return List<Reply>.from(replies);
  }
}
