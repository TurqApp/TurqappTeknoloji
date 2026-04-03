part of 'antreman_repository.dart';

extension AntremanRepositoryActionPart on AntremanRepository {
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

  Future<void> recordQuestionView({
    required String userId,
    required String questionId,
  }) async {}

  Future<void> toggleSavedQuestion({
    required String userId,
    required String questionId,
    required bool currentlySaved,
  }) async {
    if (userId.isEmpty || questionId.isEmpty) return;
    final prefsKey = _localSavedPrefsKey(userId);
    final savedMap = await _readPrefsJsonMap(prefsKey);
    if (currentlySaved) {
      savedMap.remove(questionId);
      await _writePrefsJsonMap(prefsKey, savedMap);
      return;
    }
    savedMap[questionId] = DateTime.now().millisecondsSinceEpoch;
    await _writePrefsJsonMap(prefsKey, savedMap);
  }

  Future<void> toggleLikedQuestion({
    required String userId,
    required String questionId,
    required bool currentlyLiked,
  }) async {
    if (userId.isEmpty || questionId.isEmpty) return;
    await _firestore.collection('questionBank').doc(questionId).update({
      'begeniler': currentlyLiked
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> recordSharedQuestion({
    required String userId,
    required String questionId,
  }) async {
    if (userId.isEmpty || questionId.isEmpty) return;
    await _firestore.collection('questionBank').doc(questionId).update({
      'paylasanlar': FieldValue.arrayUnion([userId]),
    });
  }

  Future<int> submitAnswer({
    required String userId,
    required QuestionBankModel question,
    required String selectedAnswer,
    required String categoryKey,
    required Map<String, dynamic> userData,
  }) async {
    if (userId.isEmpty || question.docID.isEmpty || selectedAnswer.isEmpty) {
      throw Exception('invalid_answer');
    }

    final answersKey = _localAnswersPrefsKey(userId);
    final answers = await _readPrefsJsonMap(answersKey);
    if (answers.containsKey(question.docID)) {
      throw Exception('already_answered');
    }

    final isCorrect = selectedAnswer == question.dogruCevap;
    final prefs = await SharedPreferences.getInstance();
    final currentAntPoint = prefs.getInt(_localScorePrefsKey(userId)) ??
        ((userData['antPoint'] ?? 100) as num).toInt();
    int newAntPoint = isCorrect ? currentAntPoint + 10 : currentAntPoint - 3;
    if (newAntPoint < 0) newAntPoint = 0;

    // Persist only the answered question id so we can filter it on the next
    // launch without storing the selected choice itself.
    answers[question.docID] = DateTime.now().millisecondsSinceEpoch;
    await _writePrefsJsonMap(answersKey, answers);
    await prefs.setInt(_localScorePrefsKey(userId), newAntPoint);
    return newAntPoint;
  }

  Future<void> setProgress(
    String userId,
    String categoryKey,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    if (userId.isEmpty || categoryKey.isEmpty) return;
    final prefsKey = _localProgressPrefsKey(userId, categoryKey);
    if (!merge) {
      await _writePrefsJsonMap(prefsKey, data);
      return;
    }
    final current = await _readPrefsJsonMap(prefsKey);
    current.addAll(data);
    await _writePrefsJsonMap(prefsKey, current);
  }

  Future<void> addComment({
    required String questionId,
    required Comment comment,
  }) async {
    await _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .add(comment.toJson());
    invalidateQuestionComments(questionId);
  }

  Future<void> addReply({
    required String questionId,
    required String commentDocId,
    required Reply reply,
  }) async {
    await _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .doc(commentDocId)
        .collection('Yanitlar')
        .add(reply.toJson());
    invalidateReplies(questionId, commentDocId);
  }

  Future<void> deleteComment({
    required String questionId,
    required String commentDocId,
  }) async {
    final commentRef = _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .doc(commentDocId);
    await _deleteCollectionDocs(commentRef.collection('Yanitlar'));
    await commentRef.delete();
    invalidateQuestionComments(questionId);
    invalidateReplies(questionId, commentDocId);
  }

  Future<void> deleteReply({
    required String questionId,
    required String commentDocId,
    required String replyDocId,
  }) async {
    await _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .doc(commentDocId)
        .collection('Yanitlar')
        .doc(replyDocId)
        .delete();
    invalidateReplies(questionId, commentDocId);
  }

  Future<void> updateCommentText({
    required String questionId,
    required String commentDocId,
    required String text,
  }) async {
    await _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .doc(commentDocId)
        .update({'metin': text});
    invalidateQuestionComments(questionId);
  }

  Future<void> updateReplyText({
    required String questionId,
    required String commentDocId,
    required String replyDocId,
    required String text,
  }) async {
    await _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .doc(commentDocId)
        .collection('Yanitlar')
        .doc(replyDocId)
        .update({'metin': text});
    invalidateReplies(questionId, commentDocId);
  }

  Future<void> toggleLikeComment({
    required String questionId,
    required String commentDocId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    await _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .doc(commentDocId)
        .update({
      'begeniler': currentlyLiked
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });
    invalidateQuestionComments(questionId);
  }

  Future<void> toggleLikeReply({
    required String questionId,
    required String commentDocId,
    required String replyDocId,
    required String userId,
    required bool currentlyLiked,
  }) async {
    await _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .doc(commentDocId)
        .collection('Yanitlar')
        .doc(replyDocId)
        .update({
      'begeniler': currentlyLiked
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });
    invalidateReplies(questionId, commentDocId);
  }

  void invalidateQuestionComments(String questionId) {
    _commentsCache.remove(questionId);
  }

  void invalidateReplies(String questionId, String commentDocId) {
    _repliesCache.remove('$questionId::$commentDocId');
  }
}
