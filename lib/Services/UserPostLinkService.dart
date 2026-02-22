import 'package:cloud_firestore/cloud_firestore.dart';

import '../Models/PostsModel.dart';
import '../Models/UserPostReference.dart';

/// Kullanıcı-post ilişkilerini yöneten yardımcı servis.
class UserPostLinkService {
  UserPostLinkService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<UserPostReference>> listenLikedPosts(String userId) =>
      _listenUserRefs(userId, 'liked_posts');

  Stream<List<UserPostReference>> listenSavedPosts(String userId) =>
      _listenUserRefs(userId, 'saved_posts');

  Stream<List<UserPostReference>> listenCommentedPosts(String userId) =>
      _listenUserRefs(userId, 'commented_posts');

  Stream<List<UserPostReference>> listenResharedPosts(String userId) =>
      _listenUserRefs(userId, 'reshared_posts');

  Stream<List<UserPostReference>> listenSharedAsPosts(String userId) =>
      _listenUserRefs(userId, 'shared_as_posts');

  Stream<List<UserPostReference>> _listenUserRefs(
      String userId, String collection) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(collection)
        .orderBy('timeStamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(UserPostReference.fromDoc).toList());
  }

  /// Verilen referanslar için Posts koleksiyonundan modelleri getirir.
  Future<List<PostsModel>> fetchPostsByRefs(
    String userId,
    String collection,
    List<UserPostReference> refs, {
    bool removeMissing = true,
  }) async {
    if (refs.isEmpty) return const [];

    final referenceTimes = {for (final ref in refs) ref.postId: ref.timeStamp};
    final List<PostsModel> result = [];
    final List<String> missingIds = [];

    for (var i = 0; i < refs.length; i += 10) {
      final chunk =
          refs.sublist(i, i + 10 > refs.length ? refs.length : i + 10);
      final ids = chunk.map((e) => e.postId).toSet().toList();

      final query = await _firestore
          .collection('Posts')
          .where(FieldPath.documentId, whereIn: ids)
          .get();

      final foundIds = <String>{};
      for (final doc in query.docs) {
        foundIds.add(doc.id);
        result.add(PostsModel.fromMap(doc.data(), doc.id));
      }

      for (final ref in chunk) {
        if (!foundIds.contains(ref.postId)) {
          missingIds.add(ref.docId);
        }
      }
    }

    if (removeMissing && missingIds.isNotEmpty) {
      await _removeMissingRefs(userId, collection, missingIds.toSet());
    }

    // Gönderileri zaman damgasına göre sıralı dön.
    result.sort((a, b) {
      final timeB = referenceTimes[b.docID] ?? b.timeStamp;
      final timeA = referenceTimes[a.docID] ?? a.timeStamp;
      return timeB.compareTo(timeA);
    });
    return result;
  }

  Future<void> _removeMissingRefs(
      String userId, String collection, Set<String> missingIds) async {
    if (missingIds.isEmpty) return;
    final batch = _firestore.batch();
    for (final docId in missingIds) {
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection(collection)
          .doc(docId);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  Future<List<PostsModel>> fetchLikedPosts(
          String userId, List<UserPostReference> refs) =>
      fetchPostsByRefs(userId, 'liked_posts', refs);

  Future<List<PostsModel>> fetchSavedPosts(
          String userId, List<UserPostReference> refs) =>
      fetchPostsByRefs(userId, 'saved_posts', refs);

  Future<List<PostsModel>> fetchResharedPosts(
          String userId, List<UserPostReference> refs) =>
      fetchPostsByRefs(userId, 'reshared_posts', refs);

  Future<List<PostsModel>> fetchSharedAsPosts(
          String userId, List<UserPostReference> refs) =>
      fetchPostsByRefs(userId, 'shared_as_posts', refs);
}
