import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';

import '../Models/post_interactions_models_new.dart';
import '../Models/posts_model.dart';
import '../Models/user_interactions_models.dart';
import 'offline_mode_service.dart';

enum ModerationFlagStatus {
  accepted,
  alreadyFlagged,
  disabled,
  unauthorized,
  postNotFound,
}

class ModerationFlagResult {
  const ModerationFlagResult({
    required this.status,
    this.flagCount = 0,
    this.threshold = 0,
    this.shadowHidden = false,
  });

  final ModerationFlagStatus status;
  final int flagCount;
  final int threshold;
  final bool shadowHidden;

  bool get accepted => status == ModerationFlagStatus.accepted;
  bool get alreadyFlagged => status == ModerationFlagStatus.alreadyFlagged;
  bool get isOk => accepted || alreadyFlagged;
}

/// Post etkileşimlerini yöneten servis.
///
/// Uygulamanın yeni Firestore mimarisine göre tüm etkileşimleri (beğeni,
/// yorum, kaydetme, yeniden paylaşma, görüntüleme, şikayet) Posts alt
/// koleksiyonları ile users alt koleksiyonları arasında çift yönlü olarak
/// senkronize eder.
class PostInteractionService extends GetxController {
  PostInteractionService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  static const Duration _cacheTTL = Duration(seconds: 30);
  final Map<String, _InteractionCacheEntry> _interactionStatusCache = {};
  final Set<String> _reportedByMe = <String>{};
  bool _permissionDeniedLogged = false;
  static const String _moderationConfigPath = 'adminConfig/moderation';
  static const Map<String, String> _moderationReasonMap = {
    'Uyuşturucu': 'drugs',
    'Kumar': 'gambling',
    'Çıplaklık': 'nudity',
    'Dolandırıcılık': 'scam',
    'Şiddet': 'violence',
    'Spam': 'spam',
    'Diğer': 'other',
    'drugs': 'drugs',
    'gambling': 'gambling',
    'nudity': 'nudity',
    'scam': 'scam',
    'violence': 'violence',
    'spam': 'spam',
    'other': 'other',
  };

  String? get currentUserID => _auth.currentUser?.uid;
  bool get _isOffline =>
      Get.isRegistered<OfflineModeService>() &&
      !Get.find<OfflineModeService>().isOnline.value;

  // ---------------------------------------------------------------------------
  // BEĞENİ
  // ---------------------------------------------------------------------------

  /// Post'u beğenir veya beğeniyi kaldırır. İşlem sonucunu döndürür.
  Future<bool> toggleLike(String postId) async {
    final userId = currentUserID;
    if (userId == null) return false;

    if (_isOffline) {
      final currentLiked = await _isLikedFromLocal(postId, userId);
      final target = !currentLiked;
      await OfflineModeService.instance.queueAction(
        PendingAction(
          type: 'set_like_post',
          dedupeKey: 'set_like_post:$userId:$postId',
          data: {
            'postId': postId,
            'userId': userId,
            'value': target,
          },
        ),
      );
      _updateInteractionCache(postId, like: target);
      return target;
    }

    final postRef = _postRef(postId);
    final likeDocRef = postRef.collection('likes').doc(userId);
    final userLikeRef = _userLikesRef(userId).doc(postId);

    bool? isLiked;

    await _firestore.runTransaction((tx) async {
      final likeDoc = await tx.get(likeDocRef);
      final postSnap = await tx.get(postRef);
      final stats = _statsFromSnapshot(postSnap);
      final timestamp = _nowMs();

      if (likeDoc.exists) {
        tx.delete(likeDocRef);
        tx.delete(userLikeRef);
        final next = math.max(stats.likeCount - 1, 0);
        tx.update(postRef, {'stats.likeCount': next});
        isLiked = false;
      } else {
        tx.set(likeDocRef,
            PostLikeModel(userID: userId, timeStamp: timestamp).toMap());
        tx.set(
            userLikeRef,
            UserLikedPostModel(postDocID: postId, timeStamp: timestamp)
                .toMap());
        tx.update(postRef, {'stats.likeCount': stats.likeCount + 1});
        isLiked = true;
      }
    });

    if (isLiked == true) {
      await _createNotification(postId, 'like');
    }

    _updateInteractionCache(postId, like: isLiked);
    return isLiked ?? false;
  }

  /// Kullanıcı postu beğenmiş mi kontrol eder.
  Future<bool> isPostLiked(String postId) async {
    final userId = currentUserID;
    if (userId == null) return false;
    final entry = await _userSubcollectionRepository.getEntry(
      userId,
      subcollection: 'liked_posts',
      docId: postId,
      preferCache: true,
      forceRefresh: false,
    );
    return entry != null;
  }

  // ---------------------------------------------------------------------------
  // YORUM
  // ---------------------------------------------------------------------------

  /// Ana yorum ekler ve oluşturulan yorumun ID'sini döndürür.
  Future<String?> addComment(
    String postId,
    String text, {
    List<String>? imgs,
    List<String>? videos,
  }) async {
    final userId = currentUserID;
    if (userId == null) return null;
    final safeImgs = imgs ?? const <String>[];
    final safeVideos = videos ?? const <String>[];
    if (text.trim().isEmpty && safeImgs.isEmpty && safeVideos.isEmpty) {
      return null;
    }

    if (_isOffline) {
      final suffix = userId.length > 6 ? userId.substring(0, 6) : userId;
      final tempId = 'offline_${_nowMs()}_$suffix';
      await OfflineModeService.instance.queueAction(
        PendingAction(
          type: 'add_comment_post',
          data: {
            'postId': postId,
            'userId': userId,
            'text': text,
            'imgs': safeImgs,
            'videos': safeVideos,
            'clientCommentId': tempId,
          },
        ),
      );
      _updateInteractionCache(postId, comment: true);
      return tempId;
    }

    final postRef = _postRef(postId);
    final commentRef = postRef.collection('comments').doc();
    final userCommentRef = _userCommentsRef(userId).doc(commentRef.id);
    final timestamp = _nowMs();

    await _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      final stats = _statsFromSnapshot(postSnap);

      final commentModel = PostCommentModel(
        likes: [],
        text: text,
        imgs: safeImgs,
        videos: safeVideos,
        timeStamp: timestamp,
        userID: userId,
        docID: commentRef.id,
        edited: false,
        editTimestamp: 0,
        deleted: false,
        deletedTimeStamp: 0,
        hasReplies: false,
        repliesCount: 0,
      );

      tx.set(commentRef, commentModel.toMap());
      tx.set(
          userCommentRef,
          UserCommentedPostModel(postDocID: postId, timeStamp: timestamp)
              .toMap());
      tx.update(postRef, {'stats.commentCount': stats.commentCount + 1});
    });

    await _createNotification(postId, 'comment');
    _updateInteractionCache(postId, comment: true);
    return commentRef.id;
  }

  /// Alt yorum ekler ve yeni alt yorum ID'sini döndürür.
  Future<String?> addSubComment(
    String postId,
    String commentId,
    String text, {
    List<String>? imgs,
    List<String>? videos,
  }) async {
    final userId = currentUserID;
    if (userId == null) return null;
    final safeImgs = imgs ?? const <String>[];
    final safeVideos = videos ?? const <String>[];
    if (text.trim().isEmpty && safeImgs.isEmpty && safeVideos.isEmpty) {
      return null;
    }

    final commentRef = _postRef(postId).collection('comments').doc(commentId);
    final subCommentRef = commentRef.collection('sub_comments').doc();
    final timestamp = _nowMs();

    await _firestore.runTransaction((tx) async {
      final parentSnap = await tx.get(commentRef);
      if (!parentSnap.exists) return;

      final parentData = parentSnap.data() as Map<String, dynamic>;
      final currentReplyCount = (parentData['repliesCount'] ?? 0) as num;

      final subModel = SubCommentModel(
        likes: [],
        text: text,
        imgs: safeImgs,
        videos: safeVideos,
        timeStamp: timestamp,
        userID: userId,
        docID: subCommentRef.id,
        edited: false,
        editTimestamp: 0,
        deleted: false,
        deletedTimeStamp: 0,
      );

      tx.set(subCommentRef, subModel.toMap());

      tx.update(commentRef, {
        'hasReplies': true,
        'repliesCount': currentReplyCount + 1,
      });
    });

    return subCommentRef.id;
  }

  /// Yorumu veya alt yorumu siler (soft delete) ve başarı durumunu döndürür.
  Future<bool> deleteComment(
    String postId,
    String commentId, {
    bool isSubComment = false,
    String? parentCommentId,
  }) async {
    final timestamp = _nowMs();
    bool success = false;

    try {
      await _firestore.runTransaction((tx) async {
        if (isSubComment && parentCommentId != null) {
          final parentRef =
              _postRef(postId).collection('comments').doc(parentCommentId);
          final subCommentRef =
              parentRef.collection('sub_comments').doc(commentId);

          final subSnap = await tx.get(subCommentRef);
          if (!subSnap.exists) return;

          tx.update(subCommentRef, {
            'deleted': true,
            'deletedTimeStamp': timestamp,
          });

          final parentSnap = await tx.get(parentRef);
          if (parentSnap.exists) {
            final parentData = parentSnap.data() as Map<String, dynamic>;
            final replies = (parentData['repliesCount'] ?? 0) as num;
            final newReplies = math.max(replies - 1, 0);

            tx.update(parentRef, {
              'repliesCount': newReplies,
              'hasReplies': newReplies > 0,
            });
          }

          success = true;
          return;
        }

        final postRef = _postRef(postId);
        final commentRef = postRef.collection('comments').doc(commentId);
        final commentSnap = await tx.get(commentRef);
        if (!commentSnap.exists) return;

        tx.update(commentRef, {
          'deleted': true,
          'deletedTimeStamp': timestamp,
        });

        final postSnap = await tx.get(postRef);
        final stats = _statsFromSnapshot(postSnap);
        final next = math.max(stats.commentCount - 1, 0);
        tx.update(postRef, {'stats.commentCount': next});

        success = true;
      });
    } catch (_) {
      success = false;
    }

    if (!success) {
      try {
        if (isSubComment && parentCommentId != null) {
          final parentRef =
              _postRef(postId).collection('comments').doc(parentCommentId);
          final subCommentRef =
              parentRef.collection('sub_comments').doc(commentId);
          await subCommentRef.delete();
          try {
            await _firestore.runTransaction((tx) async {
              final parentSnap = await tx.get(parentRef);
              if (!parentSnap.exists) return;
              final parentData = parentSnap.data() as Map<String, dynamic>;
              final replies = (parentData['repliesCount'] ?? 0) as num;
              final newReplies = math.max(replies - 1, 0);
              tx.update(parentRef, {
                'repliesCount': newReplies,
                'hasReplies': newReplies > 0,
              });
            });
          } catch (_) {}
          success = true;
        } else {
          final postRef = _postRef(postId);
          final commentRef = postRef.collection('comments').doc(commentId);
          await commentRef.delete();
          try {
            await postRef.set({
              'stats': {
                'commentCount': FieldValue.increment(-1),
              }
            }, SetOptions(merge: true));
          } catch (_) {}
          success = true;
        }
      } catch (_) {
        success = false;
      }
    }

    if (success) {
      _updateInteractionCache(postId, comment: false);
    }

    return success;
  }

  /// Yorumları gerçek zamanlı olarak dinler.
  Stream<List<PostCommentModel>> listenComments(String postId,
      {int limit = 50}) {
    return _postRef(postId)
        .collection('comments')
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PostCommentModel.fromFirestore(doc))
            .where((comment) => !(comment.deleted))
            .toList());
  }

  /// Alt yorumları gerçek zamanlı olarak dinler.
  Stream<List<SubCommentModel>> listenSubComments(
      String postId, String commentId,
      {int limit = 50}) {
    return _postRef(postId)
        .collection('comments')
        .doc(commentId)
        .collection('sub_comments')
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SubCommentModel.fromFirestore(doc))
            .where((comment) => !(comment.deleted))
            .toList());
  }

  /// Yorum beğenisini aç/kapa yapar.
  Future<void> toggleCommentLike(String postId, String commentId) async {
    final userId = currentUserID;
    if (userId == null) return;

    final commentRef = _postRef(postId).collection('comments').doc(commentId);
    await _toggleLikeArray(commentRef, userId);
  }

  /// Alt yorum beğenisini aç/kapa yapar.
  Future<void> toggleSubCommentLike(
      String postId, String commentId, String subCommentId) async {
    final userId = currentUserID;
    if (userId == null) return;

    final subCommentRef = _postRef(postId)
        .collection('comments')
        .doc(commentId)
        .collection('sub_comments')
        .doc(subCommentId);
    await _toggleLikeArray(subCommentRef, userId);
  }

  // ---------------------------------------------------------------------------
  // KAYDETME
  // ---------------------------------------------------------------------------

  Future<bool> toggleSave(String postId) async {
    final userId = currentUserID;
    if (userId == null) return false;

    if (_isOffline) {
      final currentSaved = await _isSavedFromLocal(postId, userId);
      final target = !currentSaved;
      await OfflineModeService.instance.queueAction(
        PendingAction(
          type: 'set_save_post',
          dedupeKey: 'set_save_post:$userId:$postId',
          data: {
            'postId': postId,
            'userId': userId,
            'value': target,
          },
        ),
      );
      _updateInteractionCache(postId, saved: target);
      return target;
    }

    final postRef = _postRef(postId);
    final saveDocRef = postRef.collection('saveds').doc(userId);
    final userSavedRef = _userSavedRef(userId).doc(postId);

    bool? isSaved;

    await _firestore.runTransaction((tx) async {
      final saveDoc = await tx.get(saveDocRef);
      final postSnap = await tx.get(postRef);
      final stats = _statsFromSnapshot(postSnap);
      final timestamp = _nowMs();

      if (saveDoc.exists) {
        tx.delete(saveDocRef);
        tx.delete(userSavedRef);
        final next = math.max(stats.savedCount - 1, 0);
        tx.update(postRef, {'stats.savedCount': next});
        isSaved = false;
      } else {
        tx.set(saveDocRef,
            PostSavedModel(userID: userId, timeStamp: timestamp).toMap());
        tx.set(
            userSavedRef,
            UserSavedPostModel(postDocID: postId, timeStamp: timestamp)
                .toMap());
        tx.update(postRef, {'stats.savedCount': stats.savedCount + 1});
        isSaved = true;
      }
    });

    _updateInteractionCache(postId, saved: isSaved);
    return isSaved ?? false;
  }

  Future<bool> isPostSaved(String postId) async {
    final userId = currentUserID;
    if (userId == null) return false;
    final entry = await _userSubcollectionRepository.getEntry(
      userId,
      subcollection: 'saved_posts',
      docId: postId,
      preferCache: true,
      forceRefresh: false,
    );
    return entry != null;
  }

  // ---------------------------------------------------------------------------
  // YENİDEN PAYLAŞMA
  // ---------------------------------------------------------------------------

  Future<bool> toggleReshare(String postId) async {
    final userId = currentUserID;
    if (userId == null) return false;

    final postRef = _postRef(postId);
    final reshareDocRef = postRef.collection('reshares').doc(userId);
    final userReshareRef = _userResharedRef(userId).doc(postId);

    bool? isReshared;

    await _firestore.runTransaction((tx) async {
      final reshareDoc = await tx.get(reshareDocRef);
      final postSnap = await tx.get(postRef);
      final stats = _statsFromSnapshot(postSnap);
      final timestamp = _nowMs();

      if (reshareDoc.exists) {
        // Yeniden paylaşımı kaldır
        tx.delete(reshareDocRef);
        tx.delete(userReshareRef);
        final next = math.max(stats.retryCount - 1, 0);
        tx.update(postRef, {'stats.retryCount': next});
        isReshared = false;
      } else {
        // Yeniden paylaşma işlemi - sadece metadata tracking
        final postData = postSnap.data();
        if (postData != null) {
          final originalUserID = postData['originalUserID'] ?? '';
          final originalPostID = postData['originalPostID'] ?? '';

          // Orijinal post bilgilerini belirle
          final String finalOriginalUserID;
          final String finalOriginalPostID;

          // Eğer orijinal post bilgisi varsa, onu kullan
          if (originalUserID.isNotEmpty) {
            finalOriginalUserID = originalUserID;
            finalOriginalPostID =
                originalPostID.isNotEmpty ? originalPostID : postId;
          } else {
            // İlk kez reshare ediliyorsa, bu post'un sahibini orijinal olarak kaydet
            finalOriginalUserID = postData['userID'] ?? '';
            finalOriginalPostID = postId;
          }

          final reshareData = PostReshareModel(
            userID: userId,
            timeStamp: timestamp,
            originalUserID: finalOriginalUserID,
            originalPostID: finalOriginalPostID,
          ).toMap();

          tx.set(reshareDocRef, reshareData);

          // User reshared posts collection'ına da ekle
          final userReshareData = UserResharedPostModel(
            postDocID: postId,
            timeStamp: timestamp,
            originalUserID: finalOriginalUserID,
            originalPostID: finalOriginalPostID,
          ).toMap();

          tx.set(userReshareRef, userReshareData);
        } else {
          // Fallback - sadece temel reshare bilgilerini kaydet
          tx.set(reshareDocRef,
              PostReshareModel(userID: userId, timeStamp: timestamp).toMap());
          tx.set(
              userReshareRef,
              UserResharedPostModel(postDocID: postId, timeStamp: timestamp)
                  .toMap());
        }

        tx.update(postRef, {'stats.retryCount': stats.retryCount + 1});
        isReshared = true;
      }
    });

    if (isReshared == true) {
      await _createNotification(postId, 'reshared_posts');
    }

    _updateInteractionCache(postId, reshared: isReshared);
    return isReshared ?? false;
  }

  // ---------------------------------------------------------------------------
  // GÖRÜNTÜLENME & ŞİKAYET
  // ---------------------------------------------------------------------------

  Future<void> recordView(String postId) async {
    final userId = currentUserID;
    if (userId == null) return;

    final postRef = _postRef(postId);
    final viewerDocRef = postRef.collection('viewers').doc(userId);

    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(viewerDocRef);
      if (existing.exists) return;

      final postSnap = await tx.get(postRef);
      final stats = _statsFromSnapshot(postSnap);

      tx.set(viewerDocRef,
          PostViewerModel(userID: userId, timeStamp: _nowMs()).toMap());
      tx.update(postRef, {'stats.statsCount': stats.statsCount + 1});
    });
  }

  Future<bool> reportPost(String postId) async {
    final userId = currentUserID;
    if (userId == null) return false;

    final postRef = _postRef(postId);
    final reporterDocRef = postRef.collection('reporters').doc(userId);
    bool reported = false;

    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(reporterDocRef);
      if (existing.exists) return;

      final postSnap = await tx.get(postRef);
      final stats = _statsFromSnapshot(postSnap);

      tx.set(reporterDocRef,
          PostReporterModel(userID: userId, timeStamp: _nowMs()).toMap());
      tx.update(postRef, {'stats.reportedCount': stats.reportedCount + 1});
      reported = true;
    });

    if (reported) {
      _reportedByMe.add(postId);
      _updateInteractionCache(postId, reported: true);
    }

    return reported;
  }

  Future<ModerationFlagResult> flagPostWithReason(
    String postId, {
    required String reason,
  }) async {
    final userId = currentUserID;
    if (userId == null) {
      return const ModerationFlagResult(
        status: ModerationFlagStatus.unauthorized,
      );
    }

    final config = await _loadModerationConfig();
    if (!config.enabled) {
      return ModerationFlagResult(
        status: ModerationFlagStatus.disabled,
        threshold: config.threshold,
      );
    }

    final postRef = _postRef(postId);
    final normalizedReason = _normalizeModerationReason(reason);

    bool alreadyFlagged = false;
    bool accepted = false;
    bool shadowHidden = false;
    int nextFlagCount = 0;
    final nowMs = _nowMs();

    await _firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;

      final postData = postSnap.data() ?? const <String, dynamic>{};
      final moderationRaw = postData['moderation'];
      final moderation = moderationRaw is Map<String, dynamic>
          ? Map<String, dynamic>.from(moderationRaw)
          : (moderationRaw is Map
              ? Map<String, dynamic>.from(moderationRaw)
              : <String, dynamic>{});

      final flaggedByRaw = moderation['flaggedBy'];
      final flaggedBy = flaggedByRaw is List
          ? flaggedByRaw.map((e) => e.toString()).toList()
          : <String>[];

      nextFlagCount = _asInt(moderation['flagCount']);
      final currentStatus = (moderation['status'] ?? 'active').toString();

      if (config.allowSingleFlagPerUser && flaggedBy.contains(userId)) {
        alreadyFlagged = true;
        return;
      }

      nextFlagCount += 1;
      shadowHidden = config.enableShadowHide &&
          nextFlagCount >= config.threshold &&
          currentStatus != 'removed';

      final updates = <String, dynamic>{
        'moderation.flagCount': nextFlagCount,
        'moderation.flaggedBy': FieldValue.arrayUnion([userId]),
        'moderation.reasonsSummary.$normalizedReason': FieldValue.increment(1),
        'moderation.lastFlagAt': nowMs,
        'moderation.ownerNotified': moderation['ownerNotified'] ?? false,
      };

      if ((moderation['status'] ?? '').toString().trim().isEmpty) {
        updates['moderation.status'] = 'active';
      }

      if (shadowHidden) {
        updates['moderation.status'] = 'shadow_hidden';
        updates['moderation.thresholdReachedAt'] = nowMs;
        updates['moderation.shadowHiddenAt'] = nowMs;
      }

      tx.update(postRef, updates);
      accepted = true;
    });

    if (alreadyFlagged) {
      return ModerationFlagResult(
        status: ModerationFlagStatus.alreadyFlagged,
        flagCount: nextFlagCount,
        threshold: config.threshold,
        shadowHidden: shadowHidden,
      );
    }

    if (!accepted) {
      return ModerationFlagResult(
        status: ModerationFlagStatus.postNotFound,
        threshold: config.threshold,
      );
    }

    _reportedByMe.add(postId);
    _updateInteractionCache(postId, reported: true);
    return ModerationFlagResult(
      status: ModerationFlagStatus.accepted,
      flagCount: nextFlagCount,
      threshold: config.threshold,
      shadowHidden: shadowHidden,
    );
  }

  // ---------------------------------------------------------------------------
  // BİLDİRİMLER & SAYIMLAR
  // ---------------------------------------------------------------------------

  Future<void> _createNotification(String postId, String type) async {
    final userId = currentUserID;
    if (userId == null) return;

    try {
      final postDoc = await _postRef(postId).get();
      final ownerId = postDoc.data()?['userID'] as String?;
      if (ownerId == null || ownerId == userId) return;

      final notification = NotificationModel(
        type: _normalizeNotifyType(type),
        fromUserID: userId,
        postID: postId,
        timeStamp: _nowMs(),
        read: false,
      ).toMap();

      await _firestore
          .collection('users')
          .doc(ownerId)
          .collection('notifications')
          .add(notification);
    } catch (e) {
      print('Create notification error: $e');
    }
  }

  String _normalizeNotifyType(String type) {
    switch (type) {
      case 'comment':
        return 'Comment';
      case 'like':
      case 'reshared_posts':
      case 'shared_as_posts':
      default:
        return 'Posts';
    }
  }

  Future<Map<String, int>> getPostInteractionCounts(String postId) async {
    try {
      final snap = await _postRef(postId).get();
      final stats = _statsFromSnapshot(snap);
      return {
        'likes': stats.likeCount.toInt(),
        'comments': stats.commentCount.toInt(),
        'saves': stats.savedCount.toInt(),
        'reshares': stats.retryCount.toInt(),
        'views': stats.statsCount.toInt(),
        'reports': stats.reportedCount.toInt(),
      };
    } catch (e) {
      print('Get interaction counts error: $e');
      return const {
        'likes': 0,
        'comments': 0,
        'saves': 0,
        'reshares': 0,
        'views': 0,
        'reports': 0,
      };
    }
  }

  Future<Map<String, bool>> getUserInteractionStatus(String postId) async {
    final userId = currentUserID;
    if (userId == null) {
      return const {
        'liked': false,
        'saved': false,
        'reshared': false,
        'reported': false,
      };
    }

    final cacheKey = _cacheKey(userId, postId);
    final cached = _interactionStatusCache[cacheKey];
    if (cached != null && !cached.isExpired(_cacheTTL)) {
      return Map<String, bool>.from(cached.status);
    }

    try {
      final futures = await Future.wait<UserSubcollectionEntry?>([
        _userSubcollectionRepository.getEntry(
          userId,
          subcollection: 'liked_posts',
          docId: postId,
          preferCache: true,
          forceRefresh: false,
        ),
        _userSubcollectionRepository.getEntry(
          userId,
          subcollection: 'saved_posts',
          docId: postId,
          preferCache: true,
          forceRefresh: false,
        ),
        _userSubcollectionRepository.getEntry(
          userId,
          subcollection: 'reshared_posts',
          docId: postId,
          preferCache: true,
          forceRefresh: false,
        ),
      ]);

      // reporters read'i Firestore rules gereği kapalı; gereksiz permission-denied
      // spamını önlemek için sadece local report cache'i kullan.
      final reported = _reportedByMe.contains(postId);

      final status = <String, bool>{
        'liked': futures[0] != null,
        'saved': futures[1] != null,
        'reshared': futures[2] != null,
        'reported': reported,
      };

      _interactionStatusCache[cacheKey] =
          _InteractionCacheEntry(status: status, fetchedAt: DateTime.now());
      return status;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (!_permissionDeniedLogged) {
          _permissionDeniedLogged = true;
          print(
              'Interaction status read denied by Firestore rules. Falling back to defaults.');
        }
        return const {
          'liked': false,
          'saved': false,
          'reshared': false,
          'reported': false,
        };
      }
      print('Get user interaction status error: $e');
      return const {
        'liked': false,
        'saved': false,
        'reshared': false,
        'reported': false,
      };
    } catch (e) {
      print('Get user interaction status error: $e');
      return const {
        'liked': false,
        'saved': false,
        'reshared': false,
        'reported': false,
      };
    }
  }

  // ---------------------------------------------------------------------------
  // YARDIMCI METODLAR
  // ---------------------------------------------------------------------------

  DocumentReference<Map<String, dynamic>> _postRef(String postId) =>
      _firestore.collection('Posts').doc(postId);

  CollectionReference<Map<String, dynamic>> _userLikesRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('liked_posts');

  CollectionReference<Map<String, dynamic>> _userSavedRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('saved_posts');

  CollectionReference<Map<String, dynamic>> _userCommentsRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('commented_posts');

  CollectionReference<Map<String, dynamic>> _userResharedRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('reshared_posts');

  int _nowMs() => DateTime.now().millisecondsSinceEpoch;

  PostStats _statsFromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data() ?? const {};
    return PostStats.fromPostData(data);
  }

  Future<void> _toggleLikeArray(
      DocumentReference<Map<String, dynamic>> ref, String userId) async {
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final likes = List<String>.from(data['likes'] ?? const []);
      final bool alreadyLiked = likes.contains(userId);

      tx.update(
          ref,
          alreadyLiked
              ? {
                  'likes': FieldValue.arrayRemove([userId])
                }
              : {
                  'likes': FieldValue.arrayUnion([userId])
                });
    });
  }

  String _cacheKey(String userId, String postId) => '$userId::$postId';

  Future<_ModerationConfigSnapshot> _loadModerationConfig() async {
    try {
      final snap = await _firestore.doc(_moderationConfigPath).get();
      final raw = snap.data() ?? const <String, dynamic>{};
      return _ModerationConfigSnapshot(
        enabled: _asBool(raw['enabled'], fallback: true),
        threshold: _asInt(raw['blackBadgeFlagThreshold'], fallback: 5),
        allowSingleFlagPerUser:
            _asBool(raw['allowSingleFlagPerUser'], fallback: true),
        enableShadowHide: _asBool(raw['enableShadowHide'], fallback: true),
      );
    } catch (_) {
      return const _ModerationConfigSnapshot(
        enabled: true,
        threshold: 5,
        allowSingleFlagPerUser: true,
        enableShadowHide: true,
      );
    }
  }

  String _normalizeModerationReason(String reason) {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) return 'other';
    return _moderationReasonMap[trimmed] ??
        _moderationReasonMap[trimmed.toLowerCase()] ??
        'other';
  }

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  bool _asBool(dynamic value, {required bool fallback}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return fallback;
  }


  void _updateInteractionCache(
    String postId, {
    bool? like,
    bool? saved,
    bool? reshared,
    bool? reported,
    bool? comment,
  }) {
    final userId = currentUserID;
    if (userId == null) return;
    final key = _cacheKey(userId, postId);
    final existing = _interactionStatusCache[key];
    if (existing == null) return;

    final updated = Map<String, bool>.from(existing.status);
    if (like != null) updated['liked'] = like;
    if (saved != null) updated['saved'] = saved;
    if (reshared != null) updated['reshared'] = reshared;
    if (reported != null) updated['reported'] = reported;
    _interactionStatusCache[key] =
        _InteractionCacheEntry(status: updated, fetchedAt: DateTime.now());
  }

  Future<bool> _isLikedFromLocal(String postId, String userId) async {
    try {
      final doc = await _postRef(postId)
          .collection('likes')
          .doc(userId)
          .get(const GetOptions(source: Source.cache));
      return doc.exists;
    } catch (_) {
      final key = _cacheKey(userId, postId);
      return _interactionStatusCache[key]?.status['liked'] ?? false;
    }
  }

  Future<bool> _isSavedFromLocal(String postId, String userId) async {
    try {
      final doc = await _postRef(postId)
          .collection('saveds')
          .doc(userId)
          .get(const GetOptions(source: Source.cache));
      return doc.exists;
    } catch (_) {
      final key = _cacheKey(userId, postId);
      return _interactionStatusCache[key]?.status['saved'] ?? false;
    }
  }
}

class _ModerationConfigSnapshot {
  const _ModerationConfigSnapshot({
    required this.enabled,
    required this.threshold,
    required this.allowSingleFlagPerUser,
    required this.enableShadowHide,
  });

  final bool enabled;
  final int threshold;
  final bool allowSingleFlagPerUser;
  final bool enableShadowHide;
}

class _InteractionCacheEntry {
  _InteractionCacheEntry({required this.status, required this.fetchedAt});

  final Map<String, bool> status;
  final DateTime fetchedAt;

  bool isExpired(Duration ttl) => DateTime.now().difference(fetchedAt) > ttl;
}
