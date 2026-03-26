part of 'post_comment_controller.dart';

PostCommentController _ensurePostCommentController({
  required String postID,
  required String userID,
  required String collection,
  required Function(bool increment)? onCommentCountChange,
  required String? tag,
  required bool permanent,
}) {
  final existing = _maybeFindPostCommentController(tag: tag);
  if (existing != null) {
    _postCommentControllerActiveTag = tag;
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
  _postCommentControllerActiveTag = tag;
  return created;
}

PostCommentController? _maybeFindPostCommentController({String? tag}) {
  final resolvedTag = (tag ?? _postCommentControllerActiveTag)?.trim();
  final normalizedTag = resolvedTag?.isEmpty == true ? null : resolvedTag;
  final isRegistered =
      Get.isRegistered<PostCommentController>(tag: normalizedTag);
  if (!isRegistered) return null;
  return Get.find<PostCommentController>(tag: normalizedTag);
}

void _handlePostCommentControllerInit(PostCommentController controller) {
  _bindPostComments(controller);
  unawaited(_loadPostOwnerNickname(controller));
}

void _bindPostComments(PostCommentController controller) {
  controller._commentSub?.cancel();
  controller._commentSub = controller._interactionService
      .listenComments(controller.postID, limit: 100)
      .listen((comments) {
    final serverComments = comments.where((c) => !c.deleted).toList();
    final serverIds = serverComments.map((c) => c.docID).toSet();

    final resolvedPending =
        controller.pendingCommentIds.where(serverIds.contains).toList();
    for (final id in resolvedPending) {
      controller.pendingCommentIds.remove(id);
      controller._pendingLocalComments.remove(id);
    }

    final pendingOnly = controller._pendingLocalComments.values
        .where((c) => !serverIds.contains(c.docID))
        .toList();

    final merged = <PostCommentModel>[
      ...pendingOnly,
      ...serverComments,
    ]..sort((a, b) => (b.timeStamp).compareTo(a.timeStamp));

    controller.list.value = merged;
  });
}

Future<void> _loadPostOwnerNickname(PostCommentController controller) async {
  try {
    final data = await controller._userSummaryResolver.resolve(
      controller.userID,
      preferCache: true,
    );
    if (data != null) {
      controller.postUserNickname.value =
          data.displayName.trim().isNotEmpty ? data.displayName : data.nickname;
    }
  } catch (_) {
    controller.postUserNickname.value = '';
  }
}

void _handlePostCommentControllerClose(PostCommentController controller) {
  controller._commentSub?.cancel();
}
