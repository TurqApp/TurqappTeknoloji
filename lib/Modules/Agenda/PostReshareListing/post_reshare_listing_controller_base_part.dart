part of 'post_reshare_listing_controller.dart';

abstract class _PostReshareListingControllerBase extends GetxController {
  _PostReshareListingControllerBase({required String postID})
      : _state = _buildPostReshareListingControllerState(postID: postID);

  final _PostReshareListingControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handlePostReshareListingOnInit(this as PostReshareListingController);
  }

  @override
  void onClose() {
    _handlePostReshareListingOnClose(this as PostReshareListingController);
    super.onClose();
  }
}

class PostReshareListingController extends _PostReshareListingControllerBase {
  PostReshareListingController({required super.postID});
}
