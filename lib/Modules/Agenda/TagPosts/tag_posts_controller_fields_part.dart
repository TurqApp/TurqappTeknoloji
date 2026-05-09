part of 'tag_posts_controller.dart';

String? _activeTagPostsControllerTag;

String _normalizeTagPostsControllerTag(String tag) => tag.trim();

TagPostsController? _maybeFindTagPostsController({String? tag}) {
  final resolvedTag = tag ?? _activeTagPostsControllerTag;
  if (resolvedTag == null || resolvedTag.isEmpty) return null;
  final isRegistered = Get.isRegistered<TagPostsController>(tag: resolvedTag);
  if (!isRegistered) return null;
  return Get.find<TagPostsController>(tag: resolvedTag);
}

TagPostsController _ensureTagPostsController({required String tag}) {
  final tagKey = _normalizeTagPostsControllerTag(tag);
  _activeTagPostsControllerTag = tagKey;
  final existing = _maybeFindTagPostsController(tag: tagKey);
  if (existing != null) return existing;
  return Get.put(
    TagPostsController(
      tag: tag,
      controllerTag: tagKey,
    ),
    tag: tagKey,
  );
}

class _TagPostsControllerState {
  _TagPostsControllerState({
    required this.tag,
    required this.controllerTag,
    TagPostsRepository? repository,
  }) : repo = repository ?? TagPostsRepository();

  final String tag;
  final String controllerTag;
  final TagPostsRepository repo;
  final RxList<PostsModel> list = <PostsModel>[].obs;
  final ScrollController scrollController = ScrollController();
  final RxInt currentVisibleIndex = RxInt(-1);
  final RxInt centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? pendingCenteredDocId;
  int fetchGeneration = 0;
  final Map<String, GlobalKey> agendaKeys = {};
  final Map<int, double> visibleFractions = <int, double>{};
  final Map<int, DateTime> visibleUpdatedAt = <int, DateTime>{};
}

extension TagPostsControllerFieldsPart on TagPostsController {
  String get tag => _state.tag;
  String get controllerTag => _state.controllerTag;
  TagPostsRepository get _repo => _state.repo;
  RxList<PostsModel> get list => _state.list;
  ScrollController get scrollController => _state.scrollController;
  RxInt get currentVisibleIndex => _state.currentVisibleIndex;
  RxInt get centeredIndex => _state.centeredIndex;
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  String? get _pendingCenteredDocId => _state.pendingCenteredDocId;
  set _pendingCenteredDocId(String? value) =>
      _state.pendingCenteredDocId = value;
  int get _fetchGeneration => _state.fetchGeneration;
  set _fetchGeneration(int value) => _state.fetchGeneration = value;
  Map<String, GlobalKey> get _agendaKeys => _state.agendaKeys;
  Map<int, double> get _visibleFractions => _state.visibleFractions;
  Map<int, DateTime> get _visibleUpdatedAt => _state.visibleUpdatedAt;
}
