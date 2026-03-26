part of 'short_content_controller.dart';

class ShortContentController extends GetxController {
  ShortContentController({
    required String postID,
    required PostsModel model,
  }) : _state = _ShortContentControllerState(postID: postID, model: model);
  final _ShortContentControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handleRuntimeInit();
  }

  @override
  void onClose() {
    _handleRuntimeClose();
    super.onClose();
  }
}
