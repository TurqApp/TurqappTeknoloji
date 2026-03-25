part of 'post_comment_controller.dart';

class PostCommentControllerRuntimePart {
  const PostCommentControllerRuntimePart(this.controller);

  final PostCommentController controller;

  void onInit() {
    controller._bindComments();
    controller._loadPostOwnerNickname();
  }

  void bindComments() {
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

  Future<void> loadPostOwnerNickname() async {
    try {
      final data = await controller._userSummaryResolver.resolve(
        controller.userID,
        preferCache: true,
      );
      if (data != null) {
        controller.postUserNickname.value = data.displayName.trim().isNotEmpty
            ? data.displayName
            : data.nickname;
      }
    } catch (_) {
      controller.postUserNickname.value = '';
    }
  }

  void onClose() {
    controller._commentSub?.cancel();
  }
}
