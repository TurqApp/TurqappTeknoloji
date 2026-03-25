import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
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

  final RxString nickname = ''.obs;
  final RxString avatarUrl = ''.obs;
  final RxList<String> likes = <String>[].obs;
  final RxList<SubCommentModel> replies = <SubCommentModel>[].obs;
  final RxMap<String, String> replyNicknames = <String, String>{}.obs;
  final RxMap<String, String> replyAvatarUrls = <String, String>{}.obs;
  final PostInteractionService _interactionService =
      PostInteractionService.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  StreamSubscription<List<SubCommentModel>>? _replySub;

  @override
  void onInit() {
    super.onInit();
    likes.assignAll(model.likes);
    _loadUserProfile(model.userID);
    _bindReplies();
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

  void _bindReplies() {
    _replySub?.cancel();
    _replySub = _interactionService
        .listenSubComments(postID, model.docID, limit: 50)
        .listen((items) {
      replies.assignAll(items);
      for (final reply in items) {
        _primeReplyProfile(reply.userID);
      }
    });
  }

  Future<void> _primeReplyProfile(String userID) async {
    final uid = userID.trim();
    if (uid.isEmpty) return;
    if (replyNicknames.containsKey(uid) && replyAvatarUrls.containsKey(uid)) {
      return;
    }
    try {
      final summary = await _userSummaryResolver.resolve(
        uid,
        preferCache: true,
      );
      if (summary == null) return;
      replyNicknames[uid] = summary.preferredName;
      replyAvatarUrls[uid] = summary.avatarUrl;
    } catch (_) {}
  }

  Future<void> toggleLike() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    final wasLiked = likes.contains(uid);
    _applyLocalLikeState(uid: uid, liked: !wasLiked);
    try {
      await _interactionService.toggleCommentLike(postID, model.docID);
    } catch (e) {
      _applyLocalLikeState(uid: uid, liked: wasLiked);
      AppSnackbar('common.error'.tr, 'comments.like_failed'.tr);
    }
  }

  void _applyLocalLikeState({
    required String uid,
    required bool liked,
  }) {
    if (liked) {
      if (!likes.contains(uid)) {
        likes.add(uid);
      }
      if (!model.likes.contains(uid)) {
        model.likes.add(uid);
      }
    } else {
      likes.remove(uid);
      model.likes.remove(uid);
    }
    final parent = PostCommentController.maybeFind(tag: commentControllerTag);
    parent?.syncCommentLikeLocally(
      commentId: model.docID,
      userId: uid,
      liked: liked,
    );
  }

  Future<bool> deleteComment() async {
    final controller =
        PostCommentController.maybeFind(tag: commentControllerTag);
    if (controller == null) return false;
    return controller.deleteComment(model.docID);
  }

  Future<bool> deleteReply(String replyId) async {
    final trimmed = replyId.trim();
    if (trimmed.isEmpty) return false;
    final ok = await _interactionService.deleteComment(
      postID,
      trimmed,
      isSubComment: true,
      parentCommentId: model.docID,
    );
    if (ok) {
      replies.removeWhere((reply) => reply.docID == trimmed);
    }
    return ok;
  }

  @override
  void onClose() {
    _replySub?.cancel();
    super.onClose();
  }
}
