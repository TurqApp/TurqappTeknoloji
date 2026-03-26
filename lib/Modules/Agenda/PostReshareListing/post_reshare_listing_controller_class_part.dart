part of 'post_reshare_listing_controller.dart';

class PostReshareListingController extends GetxController {
  PostReshareListingController({required String postID})
      : _state = _buildPostReshareListingControllerState(postID: postID);

  static const int _pageSize = 20;

  static PostReshareListingController ensure({required String tag}) =>
      _ensurePostReshareListingController(tag: tag);

  static PostReshareListingController? maybeFind({required String tag}) =>
      _maybeFindPostReshareListingController(tag: tag);

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

  void ensureQuotesLoaded() => _ensurePostReshareQuotesLoaded(this);

  Future<void> loadMoreReshares({bool initial = false}) =>
      _loadMorePostReshares(this, initial: initial);

  Future<void> loadMoreQuotes({bool initial = false}) =>
      _loadMorePostQuotes(this, initial: initial);
}
