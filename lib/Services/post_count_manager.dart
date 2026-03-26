import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

part 'post_count_manager_actions_part.dart';
part 'post_count_manager_facade_part.dart';
part 'post_count_manager_fields_part.dart';

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
