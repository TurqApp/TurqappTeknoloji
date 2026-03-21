import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Services/current_user_service.dart';

import '../../../Models/post_interactions_models_new.dart';
import '../../../Services/post_interaction_service.dart';
import 'post_comment_controller.dart';

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
    if (!Get.isRegistered<PostCommentContentController>(tag: tag)) {
      return null;
    }
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

  final RxString nickname = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxList<String> likes = <String>[].obs;
  final PostInteractionService _interactionService =
      PostInteractionService.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  @override
  void onInit() {
    super.onInit();
    likes.assignAll(model.likes);
    _loadUserProfile(model.userID);
  }

  Future<void> _loadUserProfile(String userID) async {
    try {
      final summary = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (summary != null) {
        nickname.value = summary.preferredName;
        avatarUrl.value = summary.avatarUrl;
      }
    } catch (_) {}
  }

  Future<void> toggleLike() async {
    await _interactionService.toggleCommentLike(postID, model.docID);
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;
    if (likes.contains(uid)) {
      likes.remove(uid);
    } else {
      likes.add(uid);
    }
  }

  Future<bool> deleteComment() async {
    final controller =
        PostCommentController.maybeFind(tag: commentControllerTag);
    if (controller == null) return false;
    return controller.deleteComment(model.docID);
  }
}
