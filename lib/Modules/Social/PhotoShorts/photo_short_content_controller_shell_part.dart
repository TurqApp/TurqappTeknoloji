part of 'photo_short_content_controller.dart';

class PhotoShortsContentController extends GetxController {
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
