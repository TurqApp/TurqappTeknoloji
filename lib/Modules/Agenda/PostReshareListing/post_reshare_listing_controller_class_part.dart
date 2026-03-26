part of 'post_reshare_listing_controller.dart';

class PostReshareListingController extends GetxController {
  PostReshareListingController({required String postID})
      : _state = _buildPostReshareListingControllerState(postID: postID);

  final _PostReshareListingControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _handlePostReshareListingOnInit(this);
  }

  @override
  void onClose() {
    _handlePostReshareListingOnClose(this);
    super.onClose();
  }
}
