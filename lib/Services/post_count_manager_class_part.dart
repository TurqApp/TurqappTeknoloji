part of 'post_count_manager.dart';

class PostCountManager extends GetxController {
  static PostCountManager? _instance;

  static PostCountManager? maybeFind() => _maybeFindPostCountManager();

  static PostCountManager ensure() => _ensurePostCountManager();

  static PostCountManager get instance => _postCountManagerInstance();

  final _state = _PostCountManagerState();

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
}
