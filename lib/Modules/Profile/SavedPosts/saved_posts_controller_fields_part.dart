part of 'saved_posts_controller.dart';

const Duration _savedPostsSilentRefreshInterval = Duration(minutes: 5);

class _SavedPostsControllerState {
  final RxList<PostsModel> savedAgendas = <PostsModel>[].obs;
  final RxList<PostsModel> savedPostsOnly = <PostsModel>[].obs;
  final RxList<PostsModel> savedSeries = <PostsModel>[].obs;
  final RxBool isLoading = false.obs;
  final PageController pageController = PageController(initialPage: 0);
  StreamSubscription<User?>? authSub;
  StreamSubscription<List<UserPostReference>>? savedPostsSub;
  final UserPostLinkService linkService = UserPostLinkService.ensure();
  final PostRepository postRepository = PostRepository.ensure();
  String? currentUserId;
  List<UserPostReference> latestRefs = const [];
}

extension SavedPostsControllerFieldsPart on SavedPostsController {
  RxList<PostsModel> get savedAgendas => _state.savedAgendas;
  RxList<PostsModel> get savedPostsOnly => _state.savedPostsOnly;
  RxList<PostsModel> get savedSeries => _state.savedSeries;
  RxBool get isLoading => _state.isLoading;
  PageController get pageController => _state.pageController;

  StreamSubscription<User?>? get _authSub => _state.authSub;
  set _authSub(StreamSubscription<User?>? value) => _state.authSub = value;

  StreamSubscription<List<UserPostReference>>? get _savedPostsSub =>
      _state.savedPostsSub;
  set _savedPostsSub(StreamSubscription<List<UserPostReference>>? value) =>
      _state.savedPostsSub = value;

  UserPostLinkService get _linkService => _state.linkService;
  PostRepository get _postRepository => _state.postRepository;

  String? get _currentUserId => _state.currentUserId;
  set _currentUserId(String? value) => _state.currentUserId = value;

  List<UserPostReference> get _latestRefs => _state.latestRefs;
  set _latestRefs(List<UserPostReference> value) => _state.latestRefs = value;
}
