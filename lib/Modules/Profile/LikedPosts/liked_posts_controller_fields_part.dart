part of 'liked_posts_controller.dart';

const Duration _likedPostsSilentRefreshInterval = Duration(minutes: 5);

class _LikedPostsControllerState {
  final all = <PostsModel>[].obs;
  final selection = 0.obs;
  final pageController = PageController(initialPage: 0);
  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? pendingCenteredDocId;
  StreamSubscription<User?>? authSub;
  StreamSubscription<List<UserPostReference>>? likedSub;
  final postKeys = <String, GlobalKey>{};
  String? currentUserId;
  List<UserPostReference> latestRefs = const [];
  final isLoading = false.obs;
  final UserPostLinkService linkService = UserPostLinkService.ensure();
}

extension LikedPostsControllerFieldsPart on LikedPostControllers {
  RxList<PostsModel> get all => _state.all;
  RxInt get selection => _state.selection;
  PageController get pageController => _state.pageController;
  RxInt get currentVisibleIndex => _state.currentVisibleIndex;
  RxInt get centeredIndex => _state.centeredIndex;
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  String? get _pendingCenteredDocId => _state.pendingCenteredDocId;
  set _pendingCenteredDocId(String? value) =>
      _state.pendingCenteredDocId = value;
  StreamSubscription<User?>? get _authSub => _state.authSub;
  set _authSub(StreamSubscription<User?>? value) => _state.authSub = value;
  StreamSubscription<List<UserPostReference>>? get _likedSub => _state.likedSub;
  set _likedSub(StreamSubscription<List<UserPostReference>>? value) =>
      _state.likedSub = value;
  Map<String, GlobalKey> get _postKeys => _state.postKeys;
  String? get _currentUserId => _state.currentUserId;
  set _currentUserId(String? value) => _state.currentUserId = value;
  List<UserPostReference> get _latestRefs => _state.latestRefs;
  set _latestRefs(List<UserPostReference> value) => _state.latestRefs = value;
  RxBool get isLoading => _state.isLoading;
  UserPostLinkService get _linkService => _state.linkService;
}
