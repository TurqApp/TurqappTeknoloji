part of 'edit_post_controller.dart';

abstract class _EditPostControllerBase extends GetxController {
  _EditPostControllerBase({required this.model});

  final EditPostModel model;
  final _state = _EditPostControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleEditPostControllerInit(this as EditPostController);
  }

  @override
  void onClose() {
    _handleEditPostControllerClose(this as EditPostController);
    super.onClose();
  }
}
