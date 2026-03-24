part of 'offline_mode_service.dart';

extension PendingActionExecutionPart on PendingAction {
  Future<void> execute() async {
    switch (type) {
      case 'update_profile':
        await _executeUpdateProfile();
        break;
      case 'like_post':
        await _executeLikePost();
        break;
      case 'set_like_post':
        await _executeSetLikePost();
        break;
      case 'follow_user':
        await _executeFollowUser();
        break;
      case 'set_save_post':
        await _executeSetSavePost();
        break;
      case 'add_comment_post':
        await _executeAddCommentPost();
        break;
      default:
        print('Unknown pending action type: $type');
    }
  }

  Future<void> _executeUpdateProfile() async {
    final uid = data['uid'] as String?;
    final fields = data['fields'] as Map<String, dynamic>?;
    if (uid == null || fields == null) return;

    final firestore = FirebaseFirestore.instance;
    await firestore.collection('users').doc(uid).update(fields);
  }

  Future<void> _executeLikePost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    if (postId == null || userId == null) return;

    final firestore = FirebaseFirestore.instance;
    await firestore
        .collection('Posts')
        .doc(postId)
        .collection('likes')
        .doc(userId)
        .set({'timeStamp': DateTime.now().millisecondsSinceEpoch});
  }

  Future<void> _executeSetLikePost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    final shouldLike = data['value'] == true;
    if (postId == null || userId == null) return;

    final firestore = FirebaseFirestore.instance;
    final postRef = firestore.collection('Posts').doc(postId);
    final likeRef = postRef.collection('likes').doc(userId);
    final userLikeRef = firestore
        .collection('users')
        .doc(userId)
        .collection('liked_posts')
        .doc(postId);

    await firestore.runTransaction((tx) async {
      final likeSnap = await tx.get(likeRef);
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;

      final postData = postSnap.data() ?? <String, dynamic>{};
      final stats = (postData['stats'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final currentLikeCount = (stats['likeCount'] as num?)?.toInt() ?? 0;
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
          tx.set(ownerRef, {
            'counterOfLikes': FieldValue.increment(1),
          }, SetOptions(merge: true));
        }
      } else if (!shouldLike && likeSnap.exists) {
        tx.delete(likeRef);
        tx.delete(userLikeRef);
        final next = currentLikeCount > 0 ? currentLikeCount - 1 : 0;
        tx.update(postRef, {'stats.likeCount': next});
        final currentOwnerLikes =
            (ownerSnap?.data()?['counterOfLikes'] as num?)?.toInt() ?? 0;
        if (ownerRef != null && currentOwnerLikes > 0) {
          tx.set(ownerRef, {
            'counterOfLikes': FieldValue.increment(-1),
          }, SetOptions(merge: true));
        }
      }
    });
  }

  Future<void> _executeSetSavePost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    final shouldSave = data['value'] == true;
    if (postId == null || userId == null) return;

    final firestore = FirebaseFirestore.instance;
    final postRef = firestore.collection('Posts').doc(postId);
    final saveRef = postRef.collection('saveds').doc(userId);
    final userSaveRef = firestore
        .collection('users')
        .doc(userId)
        .collection('saved_posts')
        .doc(postId);

    await firestore.runTransaction((tx) async {
      final saveSnap = await tx.get(saveRef);
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;

      final postData = postSnap.data() ?? <String, dynamic>{};
      final stats = (postData['stats'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final currentSavedCount = (stats['savedCount'] as num?)?.toInt() ?? 0;
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      if (shouldSave && !saveSnap.exists) {
        tx.set(saveRef, {'userID': userId, 'timeStamp': nowMs});
        tx.set(userSaveRef, {'postDocID': postId, 'timeStamp': nowMs});
        tx.update(postRef, {'stats.savedCount': currentSavedCount + 1});
      } else if (!shouldSave && saveSnap.exists) {
        tx.delete(saveRef);
        tx.delete(userSaveRef);
        final next = currentSavedCount > 0 ? currentSavedCount - 1 : 0;
        tx.update(postRef, {'stats.savedCount': next});
      }
    });
  }

  Future<void> _executeAddCommentPost() async {
    final postId = data['postId'] as String?;
    final userId = data['userId'] as String?;
    final text = (data['text'] ?? '').toString();
    if (postId == null || userId == null || text.trim().isEmpty) return;

    final imgs = (data['imgs'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    final videos =
        (data['videos'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];
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

    await firestore.runTransaction((tx) async {
      final postSnap = await tx.get(postRef);
      if (!postSnap.exists) return;
      final existingComment = await tx.get(commentRef);
      if (existingComment.exists) return;

      final postData = postSnap.data() ?? <String, dynamic>{};
      final stats = (postData['stats'] as Map?)?.cast<String, dynamic>() ??
          const <String, dynamic>{};
      final currentCommentCount = (stats['commentCount'] as num?)?.toInt() ?? 0;

      tx.set(commentRef, {
        'likes': <String>[],
        'text': text,
        'imgs': imgs,
        'videos': videos,
        'timeStamp': nowMs,
        'userID': userId,
        'docID': commentRef.id,
        'edited': false,
        'editTimestamp': 0,
        'deleted': false,
        'deletedTimeStamp': 0,
        'hasReplies': false,
        'repliesCount': 0,
      });
      tx.set(userCommentRef, {'postDocID': postId, 'timeStamp': nowMs});
      tx.update(postRef, {'stats.commentCount': currentCommentCount + 1});
    });
  }

  Future<void> _executeFollowUser() async {
    final targetUid = data['targetUid'] as String?;
    final currentUid = data['currentUid'] as String?;
    if (targetUid == null || currentUid == null) return;
    await FollowService.createRelationPair(
      targetUid,
      currentUid: currentUid,
      enforceModerationGuard: false,
    );
  }
}
