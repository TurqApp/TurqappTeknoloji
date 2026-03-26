part of 'saved_posts_controller.dart';

class SavedPostsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  static SavedPostsController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      SavedPostsController(),
      permanent: permanent,
    );
  }

  static SavedPostsController? maybeFind() {
    final isRegistered = Get.isRegistered<SavedPostsController>();
    if (!isRegistered) return null;
    return Get.find<SavedPostsController>();
  }

  final RxList<PostsModel> savedAgendas = <PostsModel>[].obs;
  final RxList<PostsModel> savedPostsOnly = <PostsModel>[].obs;
  final RxList<PostsModel> savedSeries = <PostsModel>[].obs;

  final isLoading = false.obs;
  final PageController pageController = PageController(initialPage: 0);

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<UserPostReference>>? _savedPostsSub;
  final UserPostLinkService _linkService = UserPostLinkService.ensure();
  final PostRepository _postRepository = PostRepository.ensure();

  String? _currentUserId;
  List<UserPostReference> _latestRefs = const [];

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  Future<void> refresh() async {
    await _refreshSavedPosts();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
