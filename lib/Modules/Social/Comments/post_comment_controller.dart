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

class PostCommentController extends GetxController {
  static String? _activeTag;

  static PostCommentController ensure({
    required String postID,
    required String userID,
    required String collection,
    Function(bool increment)? onCommentCountChange,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) {
      _activeTag = tag;
      return existing;
    }
    final created = Get.put(
      PostCommentController(
        postID: postID,
        userID: userID,
        collection: collection,
        onCommentCountChange: onCommentCountChange,
      ),
      tag: tag,
      permanent: permanent,
    );
    created.controllerTag = tag;
    _activeTag = tag;
    return created;
  }

  static PostCommentController? maybeFind({String? tag}) {
    final resolvedTag = (tag ?? _activeTag)?.trim();
    final isRegistered = Get.isRegistered<PostCommentController>(
      tag: resolvedTag?.isEmpty == true ? null : resolvedTag,
    );
    if (!isRegistered) return null;
    return Get.find<PostCommentController>(
      tag: resolvedTag?.isEmpty == true ? null : resolvedTag,
    );
  }

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
    _bindComments();
    _loadPostOwnerNickname();
  }

  void _bindComments() {
    _commentSub?.cancel();
    _commentSub = _interactionService
        .listenComments(postID, limit: 100)
        .listen((comments) {
      final serverComments = comments.where((c) => !c.deleted).toList();
      final serverIds = serverComments.map((c) => c.docID).toSet();

      // Sunucuya düşen pending yorumları local pending havuzundan çıkar.
      final resolvedPending =
          pendingCommentIds.where(serverIds.contains).toList();
      for (final id in resolvedPending) {
        pendingCommentIds.remove(id);
        _pendingLocalComments.remove(id);
      }

      final pendingOnly = _pendingLocalComments.values
          .where((c) => !serverIds.contains(c.docID))
          .toList();

      final merged = <PostCommentModel>[
        ...pendingOnly,
        ...serverComments,
      ]..sort((a, b) => (b.timeStamp).compareTo(a.timeStamp));

      list.value = merged;
    });
  }

  Future<void> _loadPostOwnerNickname() async {
    try {
      final data = await _userSummaryResolver.resolve(
        userID,
        preferCache: true,
      );
      if (data != null) {
        postUserNickname.value = data.displayName.trim().isNotEmpty
            ? data.displayName
            : data.nickname;
      }
    } catch (e) {
      postUserNickname.value = '';
    }
  }

  @override
  void onClose() {
    if (_activeTag == controllerTag) {
      _activeTag = null;
    }
    _commentSub?.cancel();
    super.onClose();
  }
}
