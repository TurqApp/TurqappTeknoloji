part of 'photo_short_content_controller.dart';

abstract class _PhotoShortContentControllerBase extends GetxController {
  _PhotoShortContentControllerBase({required PostsModel model})
      : _state = _PhotoShortsControllerState(model: model);

  final _PhotoShortsControllerState _state;

  @override
  void onInit() {
    super.onInit();
    (this as PhotoShortsContentController)._initializeRuntime();
  }

  @override
  void onClose() {
    (this as PhotoShortsContentController)._disposeRuntime();
    super.onClose();
  }
}
