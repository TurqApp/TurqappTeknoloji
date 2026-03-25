part of 'post_controller.dart';

extension PostControllerRuntimePart on PostController {
  Future<void> handleLike(String postId, PostsModel post) async {
    try {
      final isLiked = await _interactionService.toggleLike(postId);
      if (isLiked) {
        post.stats.likeCount++;
      } else {
        post.stats.likeCount--;
      }
      update(['post_$postId', 'like_$postId']);
      AppSnackbar(
        'common.success'.tr,
        isLiked
            ? 'post_controller.like_added'.tr
            : 'post_controller.like_removed'.tr,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      AppSnackbar(
        'common.error'.tr,
        'post_controller.like_failed'.trParams({'error': '$e'}),
      );
    }
  }

  Future<bool> checkLikeStatus(String postId) =>
      _interactionService.isPostLiked(postId);

  Future<bool> checkSaveStatus(String postId) =>
      _interactionService.isPostSaved(postId);

  Future<bool> checkReshareStatus(String postId) async {
    final status = await _interactionService.getUserInteractionStatus(postId);
    return status['reshared'] ?? false;
  }

  Future<void> recordView(String postId, PostsModel post) async {
    try {
      await _interactionService.recordView(postId);
    } catch (e) {
      print('View recording error: $e');
    }
  }

  Future<Map<String, int>> getInteractionCounts(String postId) =>
      _interactionService.getPostInteractionCounts(postId);

  Future<Map<String, bool>> getUserInteractionStatus(String postId) =>
      _interactionService.getUserInteractionStatus(postId);
}
