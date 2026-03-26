part of 'post_like_listing_controller.dart';

class PostLikeListingController extends GetxController {
  PostLikeListingController({required this.postID});
  static const int _pageSize = 20;

  static PostLikeListingController ensure({required String tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(PostLikeListingController(postID: tag), tag: tag);
  }

  static PostLikeListingController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<PostLikeListingController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PostLikeListingController>(tag: tag);
  }

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
