part of 'share_grid_controller.dart';

class ShareGridController extends GetxController {
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
