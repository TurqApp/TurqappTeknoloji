part of 'edit_post_controller.dart';

class EditPostController extends GetxController {
  final EditPostModel model;
  final _state = _EditPostControllerState();

  EditPostController({required this.model});

  @override
  void onInit() {
    super.onInit();
    _handleEditPostControllerInit(this);
  }

  @override
  void onClose() {
    _handleEditPostControllerClose(this);
    super.onClose();
  }
}
