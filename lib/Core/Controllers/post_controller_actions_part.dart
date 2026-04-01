part of 'post_controller.dart';

extension PostControllerActionsPart on PostController {
  Future<void> addComment(
    String postId,
    String text,
    PostsModel post, {
    List<String>? imgs,
    List<String>? videos,
  }) async {
    try {
      final safeImgs = imgs ?? const <String>[];
      final safeVideos = videos ?? const <String>[];
      if (text.trim().isEmpty && safeImgs.isEmpty && safeVideos.isEmpty) {
        AppSnackbar('common.error'.tr, 'post_controller.comment_empty'.tr);
        return;
      }

      final commentId = await _interactionService.addComment(
        postId,
        text,
        imgs: safeImgs,
        videos: safeVideos,
      );

      if (commentId != null) {
        post.stats.commentCount++;
        update(['post_$postId', 'comment_$postId']);
        AppSnackbar('common.success'.tr, 'post_controller.comment_added'.tr);
      } else {
        AppSnackbar('common.error'.tr, 'post_controller.comment_add_failed'.tr);
      }
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'post_controller.comment_add_error'.trParams({'error': '$e'}),
      );
    }
  }

  Future<void> deleteComment(
    String postId,
    String commentId,
    PostsModel post,
  ) async {
    try {
      final success =
          await _interactionService.deleteComment(postId, commentId);

      if (success) {
        post.stats.commentCount--;
        update(['post_$postId', 'comment_$postId']);
        AppSnackbar('common.success'.tr, 'post_controller.comment_deleted'.tr);
      } else {
        AppSnackbar('common.error'.tr, 'comments.delete_failed'.tr);
      }
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'post_controller.comment_delete_error'.trParams({'error': '$e'}),
      );
    }
  }

  Future<void> addSubComment(
    String postId,
    String commentId,
    String text, {
    List<String>? imgs,
    List<String>? videos,
  }) async {
    try {
      final safeImgs = imgs ?? const <String>[];
      final safeVideos = videos ?? const <String>[];
      if (text.trim().isEmpty && safeImgs.isEmpty && safeVideos.isEmpty) {
        AppSnackbar('common.error'.tr, 'post_controller.comment_empty'.tr);
        return;
      }

      final subCommentId = await _interactionService.addSubComment(
        postId,
        commentId,
        text,
        imgs: safeImgs,
        videos: safeVideos,
      );

      if (subCommentId != null) {
        update(['comment_$postId', 'subcomment_$commentId']);
        AppSnackbar('common.success'.tr, 'post_controller.reply_added'.tr);
      } else {
        AppSnackbar('common.error'.tr, 'post_controller.reply_add_failed'.tr);
      }
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'post_controller.reply_add_error'.trParams({'error': '$e'}),
      );
    }
  }

  Future<void> handleSave(String postId, PostsModel post) async {
    try {
      final isSaved = await _interactionService.toggleSave(postId);

      if (isSaved) {
        post.stats.savedCount++;
      } else {
        post.stats.savedCount--;
      }

      update(['post_$postId', 'save_$postId']);

      AppSnackbar(
        'common.success'.tr,
        isSaved ? 'post_controller.saved'.tr : 'post_controller.unsaved'.tr,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'post_controller.save_failed'.trParams({'error': '$e'}),
      );
    }
  }

  Future<void> handleReshare(String postId, PostsModel post) async {
    try {
      final isReshared = await _interactionService.toggleReshare(postId);

      if (isReshared) {
        post.stats.retryCount++;
        AppSnackbar('common.success'.tr, 'post_controller.reshared'.tr);
      } else {
        if (post.stats.retryCount > 0) post.stats.retryCount--;
        AppSnackbar('common.info'.tr, 'post_controller.reshare_removed'.tr);
      }

      update(['post_$postId', 'reshare_$postId']);
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'post_controller.reshare_error'.trParams({'error': '$e'}),
      );
    }
  }

  Future<void> reportPost(String postId, PostsModel post) async {
    try {
      final success = await _interactionService.reportPost(postId);

      if (success) {
        post.stats.reportedCount++;
        update(['post_$postId']);
        AppSnackbar('common.success'.tr, 'post.report_success'.tr);
      } else {
        AppSnackbar('common.info'.tr, 'post_controller.report_exists'.tr);
      }
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'post_controller.report_error'.trParams({'error': '$e'}),
      );
    }
  }
}
