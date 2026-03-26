part of 'post_reshare_listing_controller.dart';

class PostReshareListingController extends GetxController {
  PostReshareListingController({required this.postID});

  static const int _pageSize = 20;

  static PostReshareListingController ensure({required String tag}) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(PostReshareListingController(postID: tag), tag: tag);
  }

  static PostReshareListingController? maybeFind({required String tag}) {
    final isRegistered =
        Get.isRegistered<PostReshareListingController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PostReshareListingController>(tag: tag);
  }

  final String postID;
  final PostRepository _postRepository = PostRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final _state = _PostReshareListingControllerState();

  @override
  void onInit() {
    super.onInit();
    _PostReshareListingControllerRuntimePart.onInit(this);
  }

  @override
  void onClose() {
    _PostReshareListingControllerRuntimePart.onClose(this);
    super.onClose();
  }

  void ensureQuotesLoaded() {
    _PostReshareListingControllerRuntimePart.ensureQuotesLoaded(this);
  }

  Future<void> loadMoreReshares({bool initial = false}) {
    return _PostReshareListingControllerRuntimePart.loadMoreReshares(
      this,
      initial: initial,
    );
  }

  Future<void> loadMoreQuotes({bool initial = false}) {
    return _PostReshareListingControllerRuntimePart.loadMoreQuotes(
      this,
      initial: initial,
    );
  }
}
