part of 'post_count_manager.dart';

extension _PostCountManagerActionsX on PostCountManager {
  Future<void> updateLikeCount(
    String postID,
    String? originalPostID, {
    bool increment = true,
  }) async {
    final newCount = increment
        ? getLikeCount(postID).value + 1
        : getLikeCount(postID).value - 1;
    getLikeCount(postID).value = newCount.clamp(0, double.infinity).toInt();

    try {
      await _updateLinkedPostCounts(
        postID: postID,
        originalPostID: originalPostID,
        fieldPath: 'stats.likeCount',
        increment: increment ? 1 : -1,
        readLocal: getLikeCount,
      );
    } catch (e) {
      print('PostCountManager - updateLikeCount error: $e');
    }
  }

  Future<void> updateCommentCount(
    String postID,
    String? originalPostID, {
    bool increment = true,
  }) async {
    final newCount = increment
        ? getCommentCount(postID).value + 1
        : getCommentCount(postID).value - 1;
    getCommentCount(postID).value = newCount.clamp(0, double.infinity).toInt();

    try {
      await _updateLinkedPostCounts(
        postID: postID,
        originalPostID: originalPostID,
        fieldPath: 'stats.commentCount',
        increment: increment ? 1 : -1,
        readLocal: getCommentCount,
      );
    } catch (e) {
      print('PostCountManager - updateCommentCount error: $e');
    }
  }

  Future<void> updateSavedCount(
    String postID,
    String? originalPostID, {
    bool increment = true,
  }) async {
    final newCount = increment
        ? getSavedCount(postID).value + 1
        : getSavedCount(postID).value - 1;
    getSavedCount(postID).value = newCount.clamp(0, double.infinity).toInt();

    try {
      await _updateLinkedPostCounts(
        postID: postID,
        originalPostID: originalPostID,
        fieldPath: 'stats.savedCount',
        increment: increment ? 1 : -1,
        readLocal: getSavedCount,
      );
    } catch (e) {
      print('PostCountManager - updateSavedCount error: $e');
    }
  }

  Future<void> updateRetryCount(
    String postID,
    String? originalPostID, {
    bool increment = true,
  }) async {
    final newCount = increment
        ? getRetryCount(postID).value + 1
        : getRetryCount(postID).value - 1;
    getRetryCount(postID).value = newCount.clamp(0, double.infinity).toInt();

    try {
      await _updateLinkedPostCounts(
        postID: postID,
        originalPostID: originalPostID,
        fieldPath: 'stats.retryCount',
        increment: increment ? 1 : -1,
        readLocal: getRetryCount,
      );
    } catch (e) {
      print('PostCountManager - updateRetryCount error: $e');
    }
  }

  Future<void> updateStatsCount(String postID, {int by = 1}) async {
    final inc = by < 0 ? 0 : by;
    final newCount = getStatsCount(postID).value + inc;
    getStatsCount(postID).value = newCount.clamp(0, double.infinity).toInt();

    try {
      await AppFirestore.instance.collection('Posts').doc(postID).update({
        'stats.statsCount': FieldValue.increment(inc),
      });
    } catch (e) {
      print('PostCountManager - updateStatsCount error: $e');
    }
  }

  Future<void> _updateLinkedPostCounts({
    required String postID,
    required String? originalPostID,
    required String fieldPath,
    required int increment,
    required RxInt Function(String postId) readLocal,
  }) async {
    final firestore = AppFirestore.instance;
    final batch = firestore.batch();

    batch.update(
      firestore.collection('Posts').doc(postID),
      {fieldPath: FieldValue.increment(increment)},
    );

    if (originalPostID != null &&
        originalPostID.isNotEmpty &&
        originalPostID != postID) {
      final originalNewCount = readLocal(originalPostID).value + increment;
      readLocal(originalPostID).value =
          originalNewCount.clamp(0, double.infinity).toInt();
      batch.update(
        firestore.collection('Posts').doc(originalPostID),
        {fieldPath: FieldValue.increment(increment)},
      );
    }

    await batch.commit();
  }
}
