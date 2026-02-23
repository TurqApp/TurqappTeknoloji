import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../Models/post_interaction_models.dart';

class PostInteractionService extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserID => _auth.currentUser?.uid;

  // ========== BEĞENI İŞLEMLERİ ==========

  /// Post beğenme/beğeni kaldırma
  Future<bool> toggleLike(String postId) async {
    if (currentUserID == null) return false;

    try {
      final batch = _firestore.batch();
      final postRef = _firestore.collection('Posts').doc(postId);
      final likeRef = postRef.collection('likes').doc(currentUserID!);

      // Mevcut beğeni durumunu kontrol et
      final likeDoc = await likeRef.get();
      final isLiked = likeDoc.exists;

      if (isLiked) {
        // Beğeniyi kaldır
        batch.delete(likeRef);
        batch.update(postRef, {
          'stats.likeCount': FieldValue.increment(-1),
        });

        await batch.commit();
        return false; // artık beğenilmiyor
      } else {
        // Beğeni ekle
        final likeData = PostLikeModel(
          userID: currentUserID!,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        batch.set(likeRef, likeData.toMap());
        batch.update(postRef, {
          'stats.likeCount': FieldValue.increment(1),
        });

        await batch.commit();
        return true; // şimdi beğeniliyor
      }
    } catch (e) {
      print('Like toggle error: $e');
      return false;
    }
  }

  /// Kullanıcının postu beğenip beğenmediğini kontrol et
  Future<bool> isPostLiked(String postId) async {
    if (currentUserID == null) return false;

    try {
      final doc = await _firestore
          .collection('Posts')
          .doc(postId)
          .collection('likes')
          .doc(currentUserID!)
          .get();
      return doc.exists;
    } catch (e) {
      print('Check like error: $e');
      return false;
    }
  }

  // ========== YORUM İŞLEMLERİ ==========

  /// Yorum ekleme
  Future<String?> addComment(String postId, String text,
      {String? parentCommentID}) async {
    if (currentUserID == null) return null;

    try {
      final batch = _firestore.batch();
      final postRef = _firestore.collection('Posts').doc(postId);
      final commentRef = postRef.collection('comments').doc(); // Auto ID

      final commentData = PostCommentModel(
        userID: currentUserID!,
        text: text,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        likes: CommentLikes(),
        parentCommentID: parentCommentID,
        edited: false,
        editTimestamp: 0,
      );

      batch.set(commentRef, commentData.toMap());
      batch.update(postRef, {
        'stats.commentCount': FieldValue.increment(1),
      });

      await batch.commit();
      return commentRef.id;
    } catch (e) {
      print('Add comment error: $e');
      return null;
    }
  }

  /// Yorum silme
  Future<bool> deleteComment(String postId, String commentId) async {
    if (currentUserID == null) return false;

    try {
      final batch = _firestore.batch();
      final postRef = _firestore.collection('Posts').doc(postId);
      final commentRef = postRef.collection('comments').doc(commentId);

      // Sadece kendi yorumlarını silebilir
      final commentDoc = await commentRef.get();
      if (!commentDoc.exists || commentDoc.get('userID') != currentUserID) {
        return false;
      }

      batch.delete(commentRef);
      batch.update(postRef, {
        'stats.commentCount': FieldValue.increment(-1),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Delete comment error: $e');
      return false;
    }
  }

  /// Yorum düzenleme
  Future<bool> editComment(
      String postId, String commentId, String newText) async {
    if (currentUserID == null) return false;

    try {
      final commentRef = _firestore
          .collection('Posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);

      // Sadece kendi yorumlarını düzenleyebilir
      final commentDoc = await commentRef.get();
      if (!commentDoc.exists || commentDoc.get('userID') != currentUserID) {
        return false;
      }

      await commentRef.update({
        'text': newText,
        'edited': true,
        'editTimestamp': DateTime.now().millisecondsSinceEpoch,
      });

      return true;
    } catch (e) {
      print('Edit comment error: $e');
      return false;
    }
  }

  // ========== KAYDETME İŞLEMLERİ ==========

  /// Post kaydetme/kayıt kaldırma
  Future<bool> toggleSave(String postId) async {
    if (currentUserID == null) return false;

    try {
      final batch = _firestore.batch();
      final postRef = _firestore.collection('Posts').doc(postId);
      final saveRef = postRef.collection('saveds').doc(currentUserID!);

      // Mevcut kayıt durumunu kontrol et
      final saveDoc = await saveRef.get();
      final isSaved = saveDoc.exists;

      if (isSaved) {
        // Kaydı kaldır
        batch.delete(saveRef);
        batch.update(postRef, {
          'stats.savedCount': FieldValue.increment(-1),
        });

        await batch.commit();
        return false; // artık kaydedilmiyor
      } else {
        // Kaydet
        final saveData = PostSavedModel(
          userID: currentUserID!,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        batch.set(saveRef, saveData.toMap());
        batch.update(postRef, {
          'stats.savedCount': FieldValue.increment(1),
        });

        await batch.commit();
        return true; // şimdi kaydediliyor
      }
    } catch (e) {
      print('Save toggle error: $e');
      return false;
    }
  }

  /// Kullanıcının postu kaydetip kaydetmediğini kontrol et
  Future<bool> isPostSaved(String postId) async {
    if (currentUserID == null) return false;

    try {
      final doc = await _firestore
          .collection('Posts')
          .doc(postId)
          .collection('saveds')
          .doc(currentUserID!)
          .get();
      return doc.exists;
    } catch (e) {
      print('Check save error: $e');
      return false;
    }
  }

  // ========== YENIDEN PAYLAŞMA İŞLEMLERİ ==========

  /// Yeniden paylaşma
  Future<bool> addReshare(String postId) async {
    if (currentUserID == null) return false;

    try {
      final batch = _firestore.batch();
      final postRef = _firestore.collection('Posts').doc(postId);
      final reshareRef = postRef.collection('reshares').doc(currentUserID!);

      // Daha önce paylaşıp paylaşmadığını kontrol et
      final reshareDoc = await reshareRef.get();
      if (reshareDoc.exists) {
        return false; // Zaten paylaşılmış
      }

      final reshareData = PostReshareModel(
        userID: currentUserID!,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      batch.set(reshareRef, reshareData.toMap());
      batch.update(postRef, {
        'stats.retryCount': FieldValue.increment(1),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('Reshare error: $e');
      return false;
    }
  }

  /// Kullanıcının postu paylaşıp paylaşmadığını kontrol et
  Future<bool> isPostReshared(String postId) async {
    if (currentUserID == null) return false;

    try {
      final doc = await _firestore
          .collection('Posts')
          .doc(postId)
          .collection('reshares')
          .doc(currentUserID!)
          .get();
      return doc.exists;
    } catch (e) {
      print('Check reshare error: $e');
      return false;
    }
  }

  // ========== GÖRÜNTÜLEME İŞLEMLERİ ==========

  /// Post görüntüleme kaydı
  Future<bool> addView(String postId) async {
    if (currentUserID == null) return false;

    try {
      final batch = _firestore.batch();
      final postRef = _firestore.collection('Posts').doc(postId);
      final viewRef = postRef.collection('viewers').doc(currentUserID!);

      // Her kullanıcı için sadece bir kez sayılır
      final viewDoc = await viewRef.get();
      if (viewDoc.exists) {
        return false; // Zaten görüntülenmiş
      }

      final viewData = PostViewerModel(
        userID: currentUserID!,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      batch.set(viewRef, viewData.toMap());
      batch.update(postRef, {
        'stats.statsCount': FieldValue.increment(1),
      });

      await batch.commit();
      return true;
    } catch (e) {
      print('View error: $e');
      return false;
    }
  }

  // ========== LİSTE ALMA İŞLEMLERİ ==========

  /// Post beğenilerini getir
  Stream<List<PostLikeModel>> getPostLikes(String postId) {
    return _firestore
        .collection('Posts')
        .doc(postId)
        .collection('likes')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostLikeModel.fromFirestore(doc))
            .toList());
  }

  /// Post yorumlarını getir
  Stream<List<PostCommentModel>> getPostComments(String postId) {
    return _firestore
        .collection('Posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostCommentModel.fromFirestore(doc))
            .toList());
  }

  /// Post kayıtlarını getir
  Stream<List<PostSavedModel>> getPostSaves(String postId) {
    return _firestore
        .collection('Posts')
        .doc(postId)
        .collection('saveds')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostSavedModel.fromFirestore(doc))
            .toList());
  }

  /// Post paylaşımlarını getir
  Stream<List<PostReshareModel>> getPostReshares(String postId) {
    return _firestore
        .collection('Posts')
        .doc(postId)
        .collection('reshares')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostReshareModel.fromFirestore(doc))
            .toList());
  }

  /// Post görüntülemelerini getir
  Stream<List<PostViewerModel>> getPostViews(String postId) {
    return _firestore
        .collection('Posts')
        .doc(postId)
        .collection('viewers')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostViewerModel.fromFirestore(doc))
            .toList());
  }
}
