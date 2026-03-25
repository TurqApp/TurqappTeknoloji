import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

part 'post_count_manager_actions_part.dart';

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

  Future<void> updateLikeCount(
    String postID,
    String? originalPostID, {
    bool increment = true,
  }) =>
      _PostCountManagerActionsX(this).updateLikeCount(
        postID,
        originalPostID,
        increment: increment,
      );

  Future<void> updateCommentCount(
    String postID,
    String? originalPostID, {
    bool increment = true,
  }) =>
      _PostCountManagerActionsX(this).updateCommentCount(
        postID,
        originalPostID,
        increment: increment,
      );

  Future<void> updateSavedCount(
    String postID,
    String? originalPostID, {
    bool increment = true,
  }) =>
      _PostCountManagerActionsX(this).updateSavedCount(
        postID,
        originalPostID,
        increment: increment,
      );

  Future<void> updateRetryCount(
    String postID,
    String? originalPostID, {
    bool increment = true,
  }) =>
      _PostCountManagerActionsX(this).updateRetryCount(
        postID,
        originalPostID,
        increment: increment,
      );

  Future<void> updateStatsCount(String postID, {int by = 1}) =>
      _PostCountManagerActionsX(this).updateStatsCount(postID, by: by);

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
