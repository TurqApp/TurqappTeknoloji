part of 'short_controller.dart';

/// Kısa videoları Firestore'dan çekip saklayan ve
/// range bazlı (±7 etrafında) preload & prune desteği sunan controller
/// + AKILLI DİNAMİK KARIŞTIRMA SİSTEMİ
class ShortController extends _ShortControllerBase {
  void _log(String message) => _ShortControllerRuntimeX(this).log(message);

  bool _isEligibleShortPost(PostsModel post) =>
      _ShortControllerRuntimeX(this).isEligibleShortPost(post);

  @override
  void onInit() {
    super.onInit();
    _ShortControllerRuntimeX(this).handleOnInit();
  }

  @override
  void onClose() {
    _ShortControllerRuntimeX(this).handleOnClose();
    super.onClose();
  }
}
