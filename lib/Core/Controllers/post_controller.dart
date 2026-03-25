import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import '../../Services/post_interaction_service.dart';
import '../../Models/posts_model.dart';

part 'post_controller_actions_part.dart';

/// Post etkileşimlerini yönetmek için controller
class PostController extends GetxController {
  static PostController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PostController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static PostController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<PostController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PostController>(tag: tag);
  }

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

  /// Post kayıt durumunu kontrol et
  Future<bool> checkSaveStatus(String postId) async {
    return await _interactionService.isPostSaved(postId);
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
