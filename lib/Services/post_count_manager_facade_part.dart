part of 'post_count_manager.dart';

extension PostCountManagerFacadePart on PostCountManager {
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
