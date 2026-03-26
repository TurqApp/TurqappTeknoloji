part of 'post_like_listing_controller.dart';

class PostLikeListingController extends GetxController {
  PostLikeListingController({required this.postID});
  static const int _pageSize = 20;

  final String postID;
  final _state = _PostLikeListingControllerState();

  @override
  void onInit() {
    super.onInit();
    _PostLikeListingControllerRuntimePart(this).handleOnInit();
  }

  @override
  void onClose() {
    _PostLikeListingControllerRuntimePart(this).handleOnClose();
    super.onClose();
  }
}
