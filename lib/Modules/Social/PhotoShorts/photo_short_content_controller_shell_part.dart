part of 'photo_short_content_controller.dart';

class PhotoShortsContentController extends GetxController {
  static PhotoShortsContentController ensure({
    required PostsModel model,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PhotoShortsContentController(model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static PhotoShortsContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<PhotoShortsContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PhotoShortsContentController>(tag: tag);
  }

  final _PhotoShortsControllerState _state;

  PhotoShortsContentController({required PostsModel model})
      : _state = _PhotoShortsControllerState(model: model);

  @override
  void onInit() {
    super.onInit();
    _initializeRuntime();
  }

  @override
  void onClose() {
    _disposeRuntime();
    super.onClose();
  }
}
