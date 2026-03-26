part of 'post_like_listing_controller.dart';

class PostLikeListingController extends _PostLikeListingControllerBase {
  PostLikeListingController({required super.postID});
  static const int _pageSize = 20;
}

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
