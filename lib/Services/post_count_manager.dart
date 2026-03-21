import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class PostCountManager extends GetxController {
  static PostCountManager? _instance;

  static PostCountManager? maybeFind() {
    final isRegistered = Get.isRegistered<PostCountManager>();
    if (!isRegistered) return null;
    return Get.find<PostCountManager>();
  }

  static PostCountManager ensure() {
    final existing = maybeFind();
    if (existing != null) {
      _instance = existing;
      return existing;
    }
    final created = Get.put(PostCountManager());
    _instance = created;
    return created;
  }

  static PostCountManager get instance {
    return _instance ??= ensure();
  }

  final Map<String, RxInt> _likeCounts = {};
  final Map<String, RxInt> _commentCounts = {};
  final Map<String, RxInt> _savedCounts = {};
  final Map<String, RxInt> _retryCounts = {};
  final Map<String, RxInt> _statsCounts = {};

  RxInt getLikeCount(String postID) {
    _likeCounts[postID] ??= 0.obs;
    return _likeCounts[postID]!;
  }

  RxInt getCommentCount(String postID) {
    _commentCounts[postID] ??= 0.obs;
    return _commentCounts[postID]!;
  }

  RxInt getSavedCount(String postID) {
    _savedCounts[postID] ??= 0.obs;
    return _savedCounts[postID]!;
  }

  RxInt getRetryCount(String postID) {
    _retryCounts[postID] ??= 0.obs;
    return _retryCounts[postID]!;
  }

  RxInt getStatsCount(String postID) {
    _statsCounts[postID] ??= 0.obs;
    return _statsCounts[postID]!;
  }

  void initializeCounts(
    String postID, {
    required int likeCount,
    required int commentCount,
    required int savedCount,
    required int retryCount,
    int statsCount = 0,
  }) {
    getLikeCount(postID).value = likeCount;
    getCommentCount(postID).value = commentCount;
    getSavedCount(postID).value = savedCount;
    getRetryCount(postID).value = retryCount;
    getStatsCount(postID).value = statsCount;
  }

  Future<void> updateLikeCount(String postID, String? originalPostID,
      {bool increment = true}) async {
    // Optimistic local update
    final newCount = increment
        ? getLikeCount(postID).value + 1
        : getLikeCount(postID).value - 1;
    getLikeCount(postID).value = newCount.clamp(0, double.infinity).toInt();

    try {
      await _updateLinkedPostCounts(
        postID: postID,
        originalPostID: originalPostID,
        fieldPath: "stats.likeCount",
        increment: increment ? 1 : -1,
        readLocal: getLikeCount,
      );
    } catch (e) {
      print("PostCountManager - updateLikeCount error: $e");
    }
  }

  Future<void> updateCommentCount(String postID, String? originalPostID,
      {bool increment = true}) async {
    final newCount = increment
        ? getCommentCount(postID).value + 1
        : getCommentCount(postID).value - 1;
    getCommentCount(postID).value = newCount.clamp(0, double.infinity).toInt();

    try {
      await _updateLinkedPostCounts(
        postID: postID,
        originalPostID: originalPostID,
        fieldPath: "stats.commentCount",
        increment: increment ? 1 : -1,
        readLocal: getCommentCount,
      );
    } catch (e) {
      print("PostCountManager - updateCommentCount error: $e");
    }
  }

  Future<void> updateSavedCount(String postID, String? originalPostID,
      {bool increment = true}) async {
    final newCount = increment
        ? getSavedCount(postID).value + 1
        : getSavedCount(postID).value - 1;
    getSavedCount(postID).value = newCount.clamp(0, double.infinity).toInt();

    try {
      await _updateLinkedPostCounts(
        postID: postID,
        originalPostID: originalPostID,
        fieldPath: "stats.savedCount",
        increment: increment ? 1 : -1,
        readLocal: getSavedCount,
      );
    } catch (e) {
      print("PostCountManager - updateSavedCount error: $e");
    }
  }

  Future<void> updateRetryCount(String postID, String? originalPostID,
      {bool increment = true}) async {
    final newCount = increment
        ? getRetryCount(postID).value + 1
        : getRetryCount(postID).value - 1;
    getRetryCount(postID).value = newCount.clamp(0, double.infinity).toInt();

    try {
      await _updateLinkedPostCounts(
        postID: postID,
        originalPostID: originalPostID,
        fieldPath: "stats.retryCount",
        increment: increment ? 1 : -1,
        readLocal: getRetryCount,
      );
    } catch (e) {
      print("PostCountManager - updateRetryCount error: $e");
    }
  }

  Future<void> updateStatsCount(String postID, {int by = 1}) async {
    // Always increment by a positive value; clamp to avoid negatives
    final inc = by < 0 ? 0 : by;
    final newCount = getStatsCount(postID).value + inc;
    getStatsCount(postID).value = newCount.clamp(0, double.infinity).toInt();

    try {
      await FirebaseFirestore.instance.collection("Posts").doc(postID).update({
        "stats.statsCount": FieldValue.increment(inc),
      });
    } catch (e) {
      print("PostCountManager - updateStatsCount error: $e");
    }
  }

  void cleanupPost(String postID) {
    _likeCounts.remove(postID);
    _commentCounts.remove(postID);
    _savedCounts.remove(postID);
    _retryCounts.remove(postID);
    _statsCounts.remove(postID);
  }

  void cleanupAllCounts() {
    _likeCounts.clear();
    _commentCounts.clear();
    _savedCounts.clear();
    _retryCounts.clear();
    _statsCounts.clear();
  }

  Future<void> _updateLinkedPostCounts({
    required String postID,
    required String? originalPostID,
    required String fieldPath,
    required int increment,
    required RxInt Function(String postId) readLocal,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    batch.update(
      firestore.collection("Posts").doc(postID),
      {fieldPath: FieldValue.increment(increment)},
    );

    if (originalPostID != null &&
        originalPostID.isNotEmpty &&
        originalPostID != postID) {
      final originalNewCount = readLocal(originalPostID).value + increment;
      readLocal(originalPostID).value =
          originalNewCount.clamp(0, double.infinity).toInt();
      batch.update(
        firestore.collection("Posts").doc(originalPostID),
        {fieldPath: FieldValue.increment(increment)},
      );
    }

    await batch.commit();
  }
}
