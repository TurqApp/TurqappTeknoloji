import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Models/post_interactions_models_new.dart';
import '../../../Services/post_interaction_service.dart';
import 'post_comment_controller.dart';

part 'post_comment_content_controller_fields_part.dart';
part 'post_comment_content_controller_runtime_part.dart';
part 'post_comment_content_controller_actions_part.dart';

class PostCommentContentController extends GetxController {
  static PostCommentContentController ensure({
    required PostCommentModel model,
    required String postID,
    required String commentControllerTag,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PostCommentContentController(
        model: model,
        postID: postID,
        commentControllerTag: commentControllerTag,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static PostCommentContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<PostCommentContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PostCommentContentController>(tag: tag);
  }

  PostCommentContentController({
    required this.model,
    required this.postID,
    required this.commentControllerTag,
  });

  final PostCommentModel model;
  final String postID;
  final String commentControllerTag;
  final _state = _PostCommentContentControllerState();
  final PostInteractionService _interactionService =
      PostInteractionService.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  @override
  void onInit() {
    super.onInit();
    likes.assignAll(model.likes);
    _loadUserProfile(model.userID);
    _bindReplies();
  }

  Future<void> toggleLike() =>
      _PostCommentContentControllerActionsPart(this).toggleLike();

  Future<bool> deleteComment() =>
      _PostCommentContentControllerActionsPart(this).deleteComment();

  @override
  void onClose() {
    _replySub?.cancel();
    super.onClose();
  }
}
