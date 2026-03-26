part of 'share_grid_controller.dart';

class ShareGridController extends _ShareGridControllerBase {
  ShareGridController({
    required String postType,
    required String postID,
  }) : super(
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
