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
    _interactionService = Get.put(PostInteractionService());
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
        isLiked ? 'Beğenildi' : 'Beğeni Kaldırıldı',
        isLiked ? 'Post beğendiniz!' : 'Post beğenisi kaldırıldı',
        duration: Duration(seconds: 1),
      );
    } catch (e) {
      AppSnackbar('Hata', 'Beğeni işlemi yapılamadı: $e');
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
        AppSnackbar('Hata', 'Yorum boş olamaz');
        return;
      }

      final commentId = await _interactionService.addComment(postId, text,
          imgs: imgs, videos: videos);

      if (commentId != null) {
        // UI güncellemesi için comment count artır
        post.stats.commentCount++;

        // UI'ı güncelle
        update(['post_$postId', 'comment_$postId']);

        AppSnackbar('Başarılı', 'Yorum eklendi!');
      } else {
        AppSnackbar('Hata', 'Yorum eklenemedi');
      }
    } catch (e) {
      AppSnackbar('Hata', 'Yorum ekleme hatası: $e');
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

        AppSnackbar('Başarılı', 'Yorum silindi!');
      } else {
        AppSnackbar('Hata', 'Yorum silinemedi');
      }
    } catch (e) {
      AppSnackbar('Hata', 'Yorum silme hatası: $e');
    }
  }

  /// Alt yorum ekleme işlemi
  Future<void> addSubComment(String postId, String commentId, String text,
      {List<String>? imgs, List<String>? videos}) async {
    try {
      if (text.trim().isEmpty) {
        AppSnackbar('Hata', 'Yorum boş olamaz');
        return;
      }

      final subCommentId = await _interactionService
          .addSubComment(postId, commentId, text, imgs: imgs, videos: videos);

      if (subCommentId != null) {
        // UI'ı güncelle
        update(['comment_$postId', 'subcomment_$commentId']);

        AppSnackbar('Başarılı', 'Alt yorum eklendi!');
      } else {
        AppSnackbar('Hata', 'Alt yorum eklenemedi');
      }
    } catch (e) {
      AppSnackbar('Hata', 'Alt yorum ekleme hatası: $e');
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
        isSaved ? 'Kaydedildi' : 'Kayıt Kaldırıldı',
        isSaved ? 'Post kaydedildi!' : 'Post kayıdı kaldırıldı',
        duration: Duration(seconds: 1),
      );
    } catch (e) {
      AppSnackbar('Hata', 'Kaydetme işlemi yapılamadı: $e');
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
        AppSnackbar('Başarılı', 'Post yeniden paylaşıldı!');
      } else {
        if (post.stats.retryCount > 0) post.stats.retryCount--;
        AppSnackbar('Bilgi', 'Yeniden paylaşım kaldırıldı');
      }

      // UI'ı güncelle
      update(['post_$postId', 'reshare_$postId']);
    } catch (e) {
      AppSnackbar('Hata', 'Paylaşım hatası: $e');
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
        AppSnackbar('Başarılı', 'Post şikayet edildi');
      } else {
        AppSnackbar('Bilgi', 'Bu post daha önce şikayet edilmiş');
      }
    } catch (e) {
      AppSnackbar('Hata', 'Şikayet işlemi başarısız: $e');
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
