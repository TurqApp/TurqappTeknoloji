part of 'edit_post_controller.dart';

class EditPostController extends GetxController {
  static EditPostController ensure({
    required EditPostModel model,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(EditPostController(model: model),
        tag: tag, permanent: permanent);
  }

  static EditPostController? maybeFind({String? tag}) =>
      Get.isRegistered<EditPostController>(tag: tag)
          ? Get.find<EditPostController>(tag: tag)
          : null;

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
