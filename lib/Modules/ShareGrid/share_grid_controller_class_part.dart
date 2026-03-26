part of 'share_grid_controller.dart';

class ShareGridController extends GetxController {
  static ShareGridController ensure({
    required String postType,
    required String postID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ShareGridController(postType: postType, postID: postID),
      tag: tag,
      permanent: permanent,
    );
  }

  static ShareGridController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ShareGridController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ShareGridController>(tag: tag);
  }

  final _ShareGridControllerState _state;

  ShareGridController({
    required String postType,
    required String postID,
  }) : _state = _ShareGridControllerState(
          postType: postType,
          postID: postID,
        );

  @override
  void onInit() {
    super.onInit();
    _handleShareGridInit();
  }

  @override
  void onClose() {
    _handleShareGridClose();
    super.onClose();
  }
}
