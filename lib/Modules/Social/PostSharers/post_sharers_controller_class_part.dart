part of 'post_sharers_controller.dart';

class PostSharersController extends GetxController {
  static const int _pageSize = 20;

  static PostSharersController ensure({
    required String postID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PostSharersController(postID: postID),
      tag: tag,
      permanent: permanent,
    );
  }

  static PostSharersController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<PostSharersController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PostSharersController>(tag: tag);
  }

  final String postID;

  PostSharersController({required this.postID});

  final RxList<PostSharersModel> postSharers = <PostSharersModel>[].obs;
  final RxMap<String, Map<String, dynamic>> usersData =
      <String, Map<String, dynamic>>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final ScrollController scrollController = ScrollController();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final PostRepository _postRepository = PostRepository.ensure();
  DocumentSnapshot<Map<String, dynamic>>? _lastSharerDoc;
  String _resolvedPostId = '';
  bool _isFetching = false;
  bool _usingFallbackSharers = false;
  List<PostSharersModel> _fallbackSharers = const <PostSharersModel>[];
  int _fallbackOffset = 0;

  @override
  void onInit() {
    super.onInit();
    _handlePostSharersOnInit();
  }

  @override
  void onClose() {
    _handlePostSharersOnClose();
    super.onClose();
  }
}
