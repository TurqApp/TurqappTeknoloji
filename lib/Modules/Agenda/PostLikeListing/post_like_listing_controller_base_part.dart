part of 'post_like_listing_controller.dart';

abstract class _PostLikeListingControllerBase extends GetxController {
  _PostLikeListingControllerBase({required this.postID});

  final String postID;
  final _state = _PostLikeListingControllerState();

  @override
  void onInit() {
    super.onInit();
    _PostLikeListingControllerRuntimePart(
      this as PostLikeListingController,
    ).handleOnInit();
  }

  @override
  void onClose() {
    _PostLikeListingControllerRuntimePart(
      this as PostLikeListingController,
    ).handleOnClose();
    super.onClose();
  }
}
