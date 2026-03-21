import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import '../../Services/post_interaction_service.dart';
import '../../Models/posts_model.dart';

/// Post etkileşimlerini yönetmek için controller
class PostController extends GetxController {
  late final PostInteractionService _interactionService;

  @override
  void onInit() {
    super.onInit();
    _interactionService = PostInteractionService.ensure();
  }

  // ========== BEĞENI İŞLEMLERİ ==========

  /// Post beğenme/beğeni kaldırma işlemi
  Future<void> handleLike(String postId, PostsModel post) async {
    try {
      final isLiked = await _interactionService.toggleLike(postId);

      // UI güncellemesi için post modelini güncelle
      if (isLiked) {
        post.stats.likeCount++;
      } else {
        post.stats.likeCount--;
      }

      // UI'ı güncelle
      update(['post_$postId', 'like_$postId']);

      // Başarılı mesajı göster
      AppSnackbar(
        'common.success'.tr,
        isLiked
            ? 'post_controller.like_added'.tr
            : 'post_controller.like_removed'.tr,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      AppSnackbar('common.error'.tr,
          'post_controller.like_failed'.trParams({'error': '$e'}));
    }
  }

  /// Post beğeni durumunu kontrol et
  Future<bool> checkLikeStatus(String postId) async {
    return await _interactionService.isPostLiked(postId);
  }

  // ========== YORUM İŞLEMLERİ ==========

  /// Yorum ekleme işlemi
  Future<void> addComment(String postId, String text, PostsModel post,
      {List<String>? imgs, List<String>? videos}) async {
    try {
      if (text.trim().isEmpty) {
        AppSnackbar('common.error'.tr, 'post_controller.comment_empty'.tr);
        return;
      }

      final commentId = await _interactionService.addComment(postId, text,
          imgs: imgs, videos: videos);

      if (commentId != null) {
        // UI güncellemesi için comment count artır
        post.stats.commentCount++;

        // UI'ı güncelle
        update(['post_$postId', 'comment_$postId']);

        AppSnackbar('common.success'.tr, 'post_controller.comment_added'.tr);
      } else {
        AppSnackbar('common.error'.tr, 'post_controller.comment_add_failed'.tr);
      }
    } catch (e) {
      AppSnackbar('common.error'.tr,
          'post_controller.comment_add_error'.trParams({'error': '$e'}));
    }
  }

  /// Yorum silme işlemi
  Future<void> deleteComment(
      String postId, String commentId, PostsModel post) async {
    try {
      final success =
          await _interactionService.deleteComment(postId, commentId);

      if (success) {
        // UI güncellemesi için comment count azalt
        post.stats.commentCount--;

        // UI'ı güncelle
        update(['post_$postId', 'comment_$postId']);

        AppSnackbar('common.success'.tr, 'post_controller.comment_deleted'.tr);
      } else {
        AppSnackbar('common.error'.tr, 'comments.delete_failed'.tr);
      }
    } catch (e) {
      AppSnackbar('common.error'.tr,
          'post_controller.comment_delete_error'.trParams({'error': '$e'}));
    }
  }

  /// Alt yorum ekleme işlemi
  Future<void> addSubComment(String postId, String commentId, String text,
      {List<String>? imgs, List<String>? videos}) async {
    try {
      if (text.trim().isEmpty) {
        AppSnackbar('common.error'.tr, 'post_controller.comment_empty'.tr);
        return;
      }

      final subCommentId = await _interactionService
          .addSubComment(postId, commentId, text, imgs: imgs, videos: videos);

      if (subCommentId != null) {
        // UI'ı güncelle
        update(['comment_$postId', 'subcomment_$commentId']);

        AppSnackbar('common.success'.tr, 'post_controller.reply_added'.tr);
      } else {
        AppSnackbar('common.error'.tr, 'post_controller.reply_add_failed'.tr);
      }
    } catch (e) {
      AppSnackbar('common.error'.tr,
          'post_controller.reply_add_error'.trParams({'error': '$e'}));
    }
  }

  // ========== KAYDETME İŞLEMLERİ ==========

  /// Post kaydetme/kayıt kaldırma işlemi
  Future<void> handleSave(String postId, PostsModel post) async {
    try {
      final isSaved = await _interactionService.toggleSave(postId);

      // UI güncellemesi için post modelini güncelle
      if (isSaved) {
        post.stats.savedCount++;
      } else {
        post.stats.savedCount--;
      }

      // UI'ı güncelle
      update(['post_$postId', 'save_$postId']);

      // Başarılı mesajı göster
      AppSnackbar(
        'common.success'.tr,
        isSaved ? 'post_controller.saved'.tr : 'post_controller.unsaved'.tr,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      AppSnackbar('common.error'.tr,
          'post_controller.save_failed'.trParams({'error': '$e'}));
    }
  }

  /// Post kayıt durumunu kontrol et
  Future<bool> checkSaveStatus(String postId) async {
    return await _interactionService.isPostSaved(postId);
  }

  // ========== YENIDEN PAYLAŞMA İŞLEMLERİ ==========

  /// Yeniden paylaşma işlemi
  Future<void> handleReshare(String postId, PostsModel post) async {
    try {
      final isReshared = await _interactionService.toggleReshare(postId);

      // UI güncellemesi için retry count güncelle
      if (isReshared) {
        post.stats.retryCount++;
        AppSnackbar('common.success'.tr, 'post_controller.reshared'.tr);
      } else {
        if (post.stats.retryCount > 0) post.stats.retryCount--;
        AppSnackbar('common.info'.tr, 'post_controller.reshare_removed'.tr);
      }

      // UI'ı güncelle
      update(['post_$postId', 'reshare_$postId']);
    } catch (e) {
      AppSnackbar('common.error'.tr,
          'post_controller.reshare_error'.trParams({'error': '$e'}));
    }
  }

  /// Yeniden paylaşma durumunu kontrol et
  Future<bool> checkReshareStatus(String postId) async {
    // Private method erişimi yerine getUserInteractionStatus kullan
    final status = await _interactionService.getUserInteractionStatus(postId);
    return status['reshared'] ?? false;
  }

  // ========== GÖRÜNTÜLEME İŞLEMLERİ ==========

  /// Post görüntüleme kaydı
  Future<void> recordView(String postId, PostsModel post) async {
    try {
      await _interactionService.recordView(postId);
      // View işlemi sessizce yapılır, UI güncellemesi stats listener'dan gelir
    } catch (e) {
      // Görüntüleme hatalarını sessizce logla
      print('View recording error: $e');
    }
  }

  // ========== ŞİKAYET İŞLEMLERİ ==========

  /// Post şikayet etme
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
      AppSnackbar('common.error'.tr,
          'post_controller.report_error'.trParams({'error': '$e'}));
    }
  }

  // ========== YARDIMCI METODLAR ==========

  /// Post etkileşim sayılarını getir
  Future<Map<String, int>> getInteractionCounts(String postId) async {
    return await _interactionService.getPostInteractionCounts(postId);
  }

  /// Kullanıcı etkileşim durumlarını getir
  Future<Map<String, bool>> getUserInteractionStatus(String postId) async {
    return await _interactionService.getUserInteractionStatus(postId);
  }
}
