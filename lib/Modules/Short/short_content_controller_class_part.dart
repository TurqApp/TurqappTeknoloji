part of 'short_content_controller.dart';

class ShortContentController extends GetxController {
  static ShortContentController ensure({
    required String postID,
    required PostsModel model,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ShortContentController(postID: postID, model: model),
      tag: tag,
      permanent: permanent,
    );
  }

  static ShortContentController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ShortContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ShortContentController>(tag: tag);
  }

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
