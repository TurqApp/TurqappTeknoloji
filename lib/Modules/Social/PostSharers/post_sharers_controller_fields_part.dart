part of 'post_sharers_controller.dart';

const int _postSharersPageSize = 20;

PostSharersController? _maybeFindPostSharersController({String? tag}) {
  final isRegistered = Get.isRegistered<PostSharersController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<PostSharersController>(tag: tag);
}

PostSharersController _ensurePostSharersController({
  required String postID,
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindPostSharersController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    PostSharersController(postID: postID),
    tag: tag,
    permanent: permanent,
  );
}

class _PostSharersControllerState {
  _PostSharersControllerState({required this.postID});

  final String postID;
  final RxList<PostSharersModel> postSharers = <PostSharersModel>[].obs;
  final RxMap<String, Map<String, dynamic>> usersData =
      <String, Map<String, dynamic>>{}.obs;
  final RxBool isLoading = true.obs;
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMore = true.obs;
  final ScrollController scrollController = ScrollController();
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final PostRepository postRepository = PostRepository.ensure();
  DocumentSnapshot<Map<String, dynamic>>? lastSharerDoc;
  String resolvedPostId = '';
  bool isFetching = false;
  bool usingFallbackSharers = false;
  List<PostSharersModel> fallbackSharers = const <PostSharersModel>[];
  int fallbackOffset = 0;
}

extension PostSharersControllerFieldsPart on PostSharersController {
  String get postID => _state.postID;
  RxList<PostSharersModel> get postSharers => _state.postSharers;
  RxMap<String, Map<String, dynamic>> get usersData => _state.usersData;
  RxBool get isLoading => _state.isLoading;
  RxBool get isLoadingMore => _state.isLoadingMore;
  RxBool get hasMore => _state.hasMore;
  ScrollController get scrollController => _state.scrollController;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  PostRepository get _postRepository => _state.postRepository;
  DocumentSnapshot<Map<String, dynamic>>? get _lastSharerDoc =>
      _state.lastSharerDoc;
  set _lastSharerDoc(DocumentSnapshot<Map<String, dynamic>>? value) =>
      _state.lastSharerDoc = value;
  String get _resolvedPostId => _state.resolvedPostId;
  set _resolvedPostId(String value) => _state.resolvedPostId = value;
  bool get _isFetching => _state.isFetching;
  set _isFetching(bool value) => _state.isFetching = value;
  bool get _usingFallbackSharers => _state.usingFallbackSharers;
  set _usingFallbackSharers(bool value) => _state.usingFallbackSharers = value;
  List<PostSharersModel> get _fallbackSharers => _state.fallbackSharers;
  set _fallbackSharers(List<PostSharersModel> value) =>
      _state.fallbackSharers = value;
  int get _fallbackOffset => _state.fallbackOffset;
  set _fallbackOffset(int value) => _state.fallbackOffset = value;
}
