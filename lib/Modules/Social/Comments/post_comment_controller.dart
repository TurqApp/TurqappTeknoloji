import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '../../../Core/Services/giphy_picker_service.dart';
import '../../../Core/Services/user_summary_resolver.dart';
import '../../../Core/blocked_texts.dart';
import '../../../Core/functions.dart';
import '../../../Models/post_interactions_models_new.dart';
import '../../../Services/current_user_service.dart';
import '../../../Services/post_interaction_service.dart';

part 'post_comment_controller_actions_part.dart';
part 'post_comment_controller_runtime_part.dart';

class PostCommentController extends GetxController {
  static String? _activeTag;

  static PostCommentController ensure({
    required String postID,
    required String userID,
    required String collection,
    Function(bool increment)? onCommentCountChange,
    String? tag,
    bool permanent = false,
  }) =>
      _ensurePostCommentController(
        postID: postID,
        userID: userID,
        collection: collection,
        onCommentCountChange: onCommentCountChange,
        tag: tag,
        permanent: permanent,
      );

  static PostCommentController? maybeFind({String? tag}) =>
      _maybeFindPostCommentController(tag: tag);

  PostCommentController({
    required this.postID,
    required this.userID,
    required this.collection,
    this.onCommentCountChange,
  });

  final String postID;
  final String collection;
  final String userID;
  final Function(bool increment)? onCommentCountChange;
  String? controllerTag;

  final CurrentUserService userService = CurrentUserService.instance;
  final PostInteractionService _interactionService =
      PostInteractionService.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  final RxList<PostCommentModel> list = <PostCommentModel>[].obs;
  final RxSet<String> pendingCommentIds = <String>{}.obs;
  final RxString postUserNickname = ''.obs;
  final RxString replyingToCommentId = ''.obs;
  final RxString replyingToNickname = ''.obs;
  final RxString selectedGifUrl = ''.obs;
  final RxString lastSuccessfulCommentId = ''.obs;
  final RxString lastSuccessfulSendText = ''.obs;
  final RxBool lastSuccessfulSendWasReply = false.obs;
  final RxString lastDeletedCommentId = ''.obs;
  final RxString lastDeletedCommentText = ''.obs;
  final Map<String, PostCommentModel> _pendingLocalComments = {};

  StreamSubscription<List<PostCommentModel>>? _commentSub;

  @override
  void onInit() {
    super.onInit();
    if ((controllerTag ?? '').trim().isNotEmpty) {
      _activeTag = controllerTag;
    }
    _handlePostCommentControllerInit(this);
  }

  @override
  void onClose() {
    if (_activeTag == controllerTag) {
      _activeTag = null;
    }
    _handlePostCommentControllerClose(this);
    super.onClose();
  }
}
