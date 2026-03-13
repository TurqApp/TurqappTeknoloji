import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';
import 'package:turqappv2/Modules/Education/Antreman3/AntremanComments/antreman_comments_controller.dart';

class AntremanRepository {
  AntremanRepository._();

  static AntremanRepository? _instance;
  static AntremanRepository ensure() => _instance ??= AntremanRepository._();

  static const String _scoreCollection = 'questionBankSkor';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, List<Comment>> _commentsCache = <String, List<Comment>>{};
  final Map<String, List<Reply>> _repliesCache = <String, List<Reply>>{};
  Map<String, List<String>>? _uniqueFieldsCache;
  DateTime? _uniqueFieldsCachedAt;
  static const Duration _uniqueFieldsTtl = Duration(hours: 12);

  String _monthKey([DateTime? now]) {
    final current = now ?? DateTime.now();
    final month = current.month.toString().padLeft(2, '0');
    return '${current.year}-$month';
  }

  Stream<int?> scoreStream(String userId, {DateTime? now}) {
    if (userId.isEmpty) {
      return Stream<int?>.value(null);
    }
    return _firestore
        .collection(_scoreCollection)
        .doc(_monthKey(now))
        .collection('items')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return (snapshot.data()?['antPoint'] as num?)?.toInt();
    });
  }

  Stream<int> commentCountStream(String questionId) {
    if (questionId.isEmpty) {
      return Stream<int>.value(0);
    }
    return _firestore
        .collection('questionBank')
        .doc(questionId)
        .collection('Yorumlar')
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Future<int?> getMonthlyScore(String userId, {DateTime? now}) async {
    if (userId.isEmpty) return null;
    final doc = await _firestore
        .collection(_scoreCollection)
        .doc(_monthKey(now))
        .collection('items')
        .doc(userId)
        .get();
    if (!doc.exists) return null;
    return (doc.data()?['antPoint'] as num?)?.toInt();
  }

  Future<List<Map<String, dynamic>>> fetchLeaderboardPage({
    required String monthKey,
    required int pageSize,
    DocumentSnapshot<Map<String, dynamic>>? lastDocument,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection(_scoreCollection)
        .doc(monthKey)
        .collection('items')
        .orderBy('antPoint', descending: true)
        .limit(pageSize);
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => <String, dynamic>{...doc.data(), 'userID': doc.id, '_doc': doc})
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
      data['categoryKey'] = data['categoryKey'] ?? '$anaBaslik|$sinavTuru|$ders';
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
        now.difference(_uniqueFieldsCachedAt!) <= _uniqueFieldsTtl;
    if (!forceRefresh && preferCache && hasFreshCache) {
      return {
        'anaBaslik': List<String>.from(_uniqueFieldsCache!['anaBaslik'] ?? const []),
        'ders': List<String>.from(_uniqueFieldsCache!['ders'] ?? const []),
        'sinavTuru': List<String>.from(_uniqueFieldsCache!['sinavTuru'] ?? const []),
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
    int limit = 200,
  }) async {
    if (userId.isEmpty) return const <String>[];
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('qSaved')
        .orderBy('savedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => doc.id).toList(growable: false);
  }

  Future<Map<String, String>> fetchUserAnswers(
    String userId,
    List<String> docIds,
  ) async {
    final out = <String, String>{};
    if (userId.isEmpty || docIds.isEmpty) return out;
    for (int i = 0; i < docIds.length; i += 10) {
      final chunk = docIds.sublist(i, (i + 10) > docIds.length ? docIds.length : i + 10);
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('qAnswers')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final answer = doc.data()['answer'] as String?;
        if (answer != null && answer.isNotEmpty) {
          out[doc.id] = answer;
        }
      }
    }
    return out;
  }

  Future<Set<String>> fetchSavedIds(String userId, List<String> docIds) async {
    final out = <String>{};
    if (userId.isEmpty || docIds.isEmpty) return out;
    for (int i = 0; i < docIds.length; i += 10) {
      final chunk = docIds.sublist(i, (i + 10) > docIds.length ? docIds.length : i + 10);
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('qSaved')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      out.addAll(snap.docs.map((d) => d.id));
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

    final questionRef = _firestore.collection('questionBank').doc(question.docID);
    final userRef = _firestore.collection('users').doc(userId);
    final scoreRef = _firestore
        .collection(_scoreCollection)
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

  Future<Map<String, dynamic>?> getProgress(
    String userId,
    String categoryKey,
  ) async {
    if (userId.isEmpty || categoryKey.isEmpty) return null;
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('qProgress')
        .doc(categoryKey)
        .get();
    if (!doc.exists) return null;
    return Map<String, dynamic>.from(doc.data() ?? const <String, dynamic>{});
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

  Future<List<Reply>> fetchReplies(String questionId, String commentDocId) async {
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

    final replies = snapshot.docs
        .map((doc) => Reply.fromJson(doc.id, doc.data()))
        .toList();
    _repliesCache[cacheKey] = replies;
    return List<Reply>.from(replies);
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
