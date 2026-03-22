part of 'antreman_repository.dart';

extension AntremanRepositoryActionPart on AntremanRepository {
  Future<void> recordQuestionView({
    required String userId,
    required String questionId,
  }) async {
    if (userId.isEmpty || questionId.isEmpty) return;
    final viewRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('qViews')
        .doc(questionId);
    final existing = await viewRef.get();
    if (existing.exists) return;
    final batch = _firestore.batch();
    batch.set(viewRef, {
      'questionId': questionId,
      'viewedAt': DateTime.now().millisecondsSinceEpoch,
    });
    batch.update(
      _firestore.collection('questionBank').doc(questionId),
      {'viewCount': FieldValue.increment(1)},
    );
    await batch.commit();
  }

  Future<void> toggleSavedQuestion({
    required String userId,
    required String questionId,
    required bool currentlySaved,
  }) async {
    if (userId.isEmpty || questionId.isEmpty) return;
    final savedRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('qSaved')
        .doc(questionId);
    if (currentlySaved) {
      await savedRef.delete();
      return;
    }
    await savedRef.set({
      'questionId': questionId,
      'savedAt': DateTime.now().millisecondsSinceEpoch,
    });
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
    final answerRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('qAnswers')
        .doc(question.docID);
    final existingAnswer = await answerRef.get();
    if (existingAnswer.exists) {
      throw Exception('already_answered');
    }

    final isCorrect = selectedAnswer == question.dogruCevap;
    final currentAntPoint = ((userData['antPoint'] ?? 100) as num).toInt();
    int newAntPoint = isCorrect ? currentAntPoint + 10 : currentAntPoint - 3;
    if (newAntPoint < 0) newAntPoint = 0;

    final questionRef =
        _firestore.collection('questionBank').doc(question.docID);
    final userRef = _firestore.collection('users').doc(userId);
    final scoreRef = _firestore
        .collection(AntremanRepository._scoreCollection)
        .doc(_monthKey())
        .collection('items')
        .doc(userId);
    final profileName = (userData['displayName'] ??
            userData['username'] ??
            userData['nickname'] ??
            '')
        .toString();
    final profileImage = (userData['avatarUrl'] ?? '').toString();

    final batch = _firestore.batch();
    batch.set(answerRef, {
      'questionId': question.docID,
      'answer': selectedAnswer,
      'isCorrect': isCorrect,
      'categoryKey': categoryKey,
      'answeredAt': DateTime.now().millisecondsSinceEpoch,
    });
    batch.set(
      questionRef,
      {
        isCorrect ? 'correctCount' : 'wrongCount': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
    batch.set(userRef, {'antPoint': newAntPoint}, SetOptions(merge: true));
    batch.set(
      scoreRef,
      {
        'userID': userId,
        'displayName': profileName,
        'nickname': profileName,
        'firstName': (userData['firstName'] ?? '').toString(),
        'lastName': (userData['lastName'] ?? '').toString(),
        'avatarUrl': profileImage,
        'rozet': (userData['rozet'] ?? '').toString(),
        'antPoint': newAntPoint,
        'updatedDate': DateTime.now().millisecondsSinceEpoch,
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    return newAntPoint;
  }

  Future<void> setProgress(
    String userId,
    String categoryKey,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    if (userId.isEmpty || categoryKey.isEmpty) return;
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('qProgress')
        .doc(categoryKey)
        .set(data, SetOptions(merge: merge));
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
    await _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .doc(commentDocId)
        .delete();
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
