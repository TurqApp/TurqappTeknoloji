part of 'offline_mode_service.dart';

extension PendingActionExecutionPart on PendingAction {
  int _asInt(Object? value) {
    if (value is num) return value.toInt();
    if (value is String) {
      final normalized = value.trim();
      final parsed = int.tryParse(normalized);
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(normalized);
      if (parsedNum != null) return parsedNum.toInt();
    }
    return 0;
  }

  bool _asBool(Object? value, {bool fallback = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized.isEmpty) return fallback;
      switch (normalized) {
        case 'true':
        case '1':
        case 'yes':
        case 'y':
        case 'on':
          return true;
        case 'false':
        case '0':
        case 'no':
        case 'n':
        case 'off':
          return false;
      }
    }
    return fallback;
  }

  Future<PendingActionExecutionResult> execute() async {
    switch (type) {
      case 'update_profile':
        return _executeUpdateProfile();
      case 'like_post':
        return _executeLikePost();
      case 'set_like_post':
        return _executeSetLikePost();
      case 'follow_user':
        return _executeFollowUser();
      case 'set_save_post':
        return _executeSetSavePost();
      case 'add_comment_post':
        return _executeAddCommentPost();
      default:
        print('Unknown pending action type: $type');
        return PendingActionExecutionResult.skipped('unknown_type:$type');
    }
  }

  Future<PendingActionExecutionResult> _executeUpdateProfile() async {
    final uid = data['uid'] as String?;
    final fields = data['fields'] as Map<String, dynamic>?;
    if (uid == null || fields == null) {
      return PendingActionExecutionResult.skipped('invalid_profile_payload');
    }

    final firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(uid).update(fields);
    return const PendingActionExecutionResult.applied();
  }

  Future<PendingActionExecutionResult> _executeLikePost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    if (postId == null || userId == null) {
      return PendingActionExecutionResult.skipped('invalid_like_payload');
    }

    final firestore = FirebaseFirestore.instance;
    final postSnap = await firestore.collection('Posts').doc(postId).get();
    if (!postSnap.exists) {
      return PendingActionExecutionResult.skipped('post_missing');
    }
    await firestore
        .collection('Posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .set({'timeStamp': DateTime.now().millisecondsSinceEpoch});
    return const PendingActionExecutionResult.applied();
  }

  Future<PendingActionExecutionResult> _executeSetLikePost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    final shouldLike = _asBool(data['value']);
    if (postId == null || userId == null) {
      return PendingActionExecutionResult.skipped('invalid_like_payload');
    }

    final firestore = FirebaseFirestore.instance;
    final postRef = firestore.collection('Posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);
    final userLikeRef = firestore
        .collection('users')
        .doc(userId)
        .collection('liked_posts')
        .doc(postId);

    return firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) {
        return PendingActionExecutionResult.skipped('post_missing');
      }

      final postData = postSnap.data() ?? <String, dynamic>{};
      final stats = (postData['stats'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final currentLikeCount = _asInt(stats['likeCount']);
      final ownerId = (postData['userID'] ?? '').toString().trim();
      DocumentReference<Map<String, dynamic>>? ownerRef;
      DocumentSnapshot<Map<String, dynamic>>? ownerSnap;
      if (ownerId.isNotEmpty) {
        ownerRef = firestore.collection('users').doc(ownerId);
        ownerSnap = await tx.get(ownerRef);
      }
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (shouldLike && !likeSnap.exists) {
        tx.set(likeRef, {'userID': userId, 'timeStamp': nowMs});
        tx.set(userLikeRef, {'postDocID': postId, 'timeStamp': nowMs});
        tx.update(postRef, {'stats.likeCount': currentLikeCount + 1});
        if (ownerRef != null) {
          tx.set(
              ownerRef,
              {
                'counterOfLikes': FieldValue.increment(1),
              },
              SetOptions(merge: true));
        }
        return const PendingActionExecutionResult.applied();
      }

      if (!shouldLike && likeSnap.exists) {
        tx.delete(likeRef);
        tx.delete(userLikeRef);
        final next = currentLikeCount > 0 ? currentLikeCount - 1 : 0;
        tx.update(postRef, {'stats.likeCount': next});
        final currentOwnerLikes = _asInt(ownerSnap?.data()?['counterOfLikes']);
        if (ownerRef != null && currentOwnerLikes > 0) {
          tx.set(
              ownerRef,
              {
                'counterOfLikes': FieldValue.increment(-1),
              },
              SetOptions(merge: true));
        }
        return const PendingActionExecutionResult.applied();
      }
      return const PendingActionExecutionResult.applied();
    });
  }

  Future<PendingActionExecutionResult> _executeSetSavePost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    final shouldSave = _asBool(data['value']);
    if (postId == null || userId == null) {
      return PendingActionExecutionResult.skipped('invalid_save_payload');
    }

    final firestore = FirebaseFirestore.instance;
    final postRef = firestore.collection('Posts').doc(postId);
    final saveRef = postRef.collection('saveds').doc(userId);
    final userSaveRef = firestore
        .collection('users')
        .doc(userId)
        .collection('saved_posts')
        .doc(postId);

    return firestore.runTransaction((tx) async {
      final saveSnap = await tx.get(saveRef);
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) {
        return PendingActionExecutionResult.skipped('post_missing');
      }

      final postData = postSnap.data() ?? <String, dynamic>{};
      final stats = (postData['stats'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final currentSavedCount = _asInt(stats['savedCount']);
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (shouldSave && !saveSnap.exists) {
        tx.set(saveRef, {'userID': userId, 'timeStamp': nowMs});
        tx.set(userSaveRef, {'postDocID': postId, 'timeStamp': nowMs});
        tx.update(postRef, {'stats.savedCount': currentSavedCount + 1});
        return const PendingActionExecutionResult.applied();
      }

      if (!shouldSave && saveSnap.exists) {
        tx.delete(saveRef);
        tx.delete(userSaveRef);
        final next = currentSavedCount > 0 ? currentSavedCount - 1 : 0;
        tx.update(postRef, {'stats.savedCount': next});
        return const PendingActionExecutionResult.applied();
      }
      return const PendingActionExecutionResult.applied();
    });
  }

  Future<PendingActionExecutionResult> _executeAddCommentPost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    final text = (data['text'] ?? '').toString();
    final imgs = (data['imgs'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final videos =
        (data['videos'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
    if (postId == null ||
        userId == null ||
        (text.trim().isEmpty && imgs.isEmpty && videos.isEmpty)) {
      return PendingActionExecutionResult.skipped('invalid_comment_payload');
    }
    final firestore = FirebaseFirestore.instance;
    final postRef = firestore.collection('Posts').doc(postId);
    final commentIdRaw = (data['clientCommentId'] ?? '').toString().trim();
    final commentRef = commentIdRaw.isNotEmpty
        ? postRef.collection('comments').doc(commentIdRaw)
        : postRef.collection('comments').doc();
    final userCommentRef = firestore
        .collection('users')
        .doc(userId)
        .collection('commented_posts')
        .doc(commentRef.id);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    return firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) {
        return PendingActionExecutionResult.skipped('post_missing');
      }
      final existingComment = await tx.get(commentRef);
      if (existingComment.exists) {
        return const PendingActionExecutionResult.applied();
      }

      final postData = postSnap.data() ?? <String, dynamic>{};
      final stats = (postData['stats'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final currentCommentCount = _asInt(stats['commentCount']);

      tx.set(commentRef, {
        'likes': <String>[],
        'text': text,
        'imgs': imgs,
        'videos': videos,
        'timeStamp': nowMs,
        'userID': userId,
        'edited': false,
        'editTimestamp': 0,
        'deleted': false,
        'deletedTimeStamp': 0,
        'hasReplies': false,
        'repliesCount': 0,
      });
      tx.set(userCommentRef, {'postDocID': postId, 'timeStamp': nowMs});
      tx.update(postRef, {'stats.commentCount': currentCommentCount + 1});
      return const PendingActionExecutionResult.applied();
    });
  }

  Future<PendingActionExecutionResult> _executeFollowUser() async {
    final targetUid = data['targetUid'] as String?;
    final currentUid = data['currentUid'] as String?;
    if (targetUid == null || currentUid == null) {
      return PendingActionExecutionResult.skipped('invalid_follow_payload');
    }
    await FollowService.createRelationPair(
      targetUid,
      currentUid: currentUid,
      enforceModerationGuard: false,
    );
    return const PendingActionExecutionResult.applied();
  }
}
