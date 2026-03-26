part of 'post_like_listing_controller.dart';

class _PostLikeListingControllerState {
  final PostRepository postRepository = PostRepository.ensure();
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final RxList<LikeUserItem> users = <LikeUserItem>[].obs;
  final RxList<LikeUserItem> filteredUsers = <LikeUserItem>[].obs;
  final RxString query = ''.obs;
  final TextEditingController searchController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  DocumentSnapshot<Map<String, dynamic>>? lastLikeDoc;
  bool isFetching = false;
}

extension PostLikeListingControllerFieldsPart on PostLikeListingController {
  PostRepository get _postRepository => _state.postRepository;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  RxList<LikeUserItem> get users => _state.users;
  RxList<LikeUserItem> get filteredUsers => _state.filteredUsers;
  RxString get query => _state.query;
  TextEditingController get searchController => _state.searchController;
  ScrollController get scrollController => _state.scrollController;
  RxBool get isLoadingMore => _state.isLoadingMore;
  RxBool get hasMore => _state.hasMore;

  DocumentSnapshot<Map<String, dynamic>>? get _lastLikeDoc =>
      _state.lastLikeDoc;
  set _lastLikeDoc(DocumentSnapshot<Map<String, dynamic>>? value) =>
      _state.lastLikeDoc = value;

  bool get _isFetching => _state.isFetching;
  set _isFetching(bool value) => _state.isFetching = value;
}
