import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class PostCountManager extends GetxController {
  static PostCountManager? _instance;
  static PostCountManager get instance {
    _instance ??= Get.put(PostCountManager());
    return _instance!;
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

    // Firebase atomic increment
    try {
      await FirebaseFirestore.instance.collection("Posts").doc(postID).update({
        "stats.likeCount": FieldValue.increment(increment ? 1 : -1),
      });

      // Eğer bu paylaşılmış bir post ise, orijinal postun sayacını da güncelle
      if (originalPostID != null &&
          originalPostID.isNotEmpty &&
          originalPostID != postID) {
        final originalNewCount = increment
            ? getLikeCount(originalPostID).value + 1
            : getLikeCount(originalPostID).value - 1;
        getLikeCount(originalPostID).value =
            originalNewCount.clamp(0, double.infinity).toInt();

        await FirebaseFirestore.instance
            .collection("Posts")
            .doc(originalPostID)
            .update({
          "stats.likeCount": FieldValue.increment(increment ? 1 : -1),
        });
      }
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

    // Firebase atomic increment
    try {
      await FirebaseFirestore.instance.collection("Posts").doc(postID).update({
        "stats.commentCount": FieldValue.increment(increment ? 1 : -1),
      });

      // Eğer bu paylaşılmış bir post ise, orijinal postun sayacını da güncelle
      if (originalPostID != null &&
          originalPostID.isNotEmpty &&
          originalPostID != postID) {
        final originalNewCount = increment
            ? getCommentCount(originalPostID).value + 1
            : getCommentCount(originalPostID).value - 1;
        getCommentCount(originalPostID).value =
            originalNewCount.clamp(0, double.infinity).toInt();

        await FirebaseFirestore.instance
            .collection("Posts")
            .doc(originalPostID)
            .update({
          "stats.commentCount": FieldValue.increment(increment ? 1 : -1),
        });
      }
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

    // Firebase atomic increment
    try {
      await FirebaseFirestore.instance.collection("Posts").doc(postID).update({
        "stats.savedCount": FieldValue.increment(increment ? 1 : -1),
      });

      // Eğer bu paylaşılmış bir post ise, orijinal postun sayacını da güncelle
      if (originalPostID != null &&
          originalPostID.isNotEmpty &&
          originalPostID != postID) {
        final originalNewCount = increment
            ? getSavedCount(originalPostID).value + 1
            : getSavedCount(originalPostID).value - 1;
        getSavedCount(originalPostID).value =
            originalNewCount.clamp(0, double.infinity).toInt();

        await FirebaseFirestore.instance
            .collection("Posts")
            .doc(originalPostID)
            .update({
          "stats.savedCount": FieldValue.increment(increment ? 1 : -1),
        });
      }
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

    // Firebase atomic increment
    try {
      await FirebaseFirestore.instance.collection("Posts").doc(postID).update({
        "stats.retryCount": FieldValue.increment(increment ? 1 : -1),
      });

      // Eğer bu paylaşılmış bir post ise, orijinal postun sayacını da güncelle
      if (originalPostID != null &&
          originalPostID.isNotEmpty &&
          originalPostID != postID) {
        final originalNewCount = increment
            ? getRetryCount(originalPostID).value + 1
            : getRetryCount(originalPostID).value - 1;
        getRetryCount(originalPostID).value =
            originalNewCount.clamp(0, double.infinity).toInt();

        await FirebaseFirestore.instance
            .collection("Posts")
            .doc(originalPostID)
            .update({
          "stats.retryCount": FieldValue.increment(increment ? 1 : -1),
        });
      }
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
      await FirebaseFirestore.instance
          .collection("Posts")
          .doc(postID)
          .update({
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
}
