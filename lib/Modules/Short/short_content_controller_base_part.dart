part of 'short_content_controller.dart';

abstract class _ShortContentControllerBase extends GetxController {
  _ShortContentControllerBase({
    required String postID,
    required PostsModel model,
  }) : _state = _ShortContentControllerState(postID: postID, model: model);

  final _ShortContentControllerState _state;

  @override
  void onInit() {
    super.onInit();
    (this as ShortContentController)._handleRuntimeInit();
  }

  @override
  void onClose() {
    (this as ShortContentController)._handleRuntimeClose();
    super.onClose();
  }
}
