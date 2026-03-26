part of 'tag_posts_controller.dart';

TagPostsController? _maybeFindTagPostsController({String? tag}) {
  final resolvedTag = tag ?? TagPostsController._activeTag;
  if (resolvedTag == null || resolvedTag.isEmpty) return null;
  final isRegistered = Get.isRegistered<TagPostsController>(tag: resolvedTag);
  if (!isRegistered) return null;
  return Get.find<TagPostsController>(tag: resolvedTag);
}

TagPostsController _ensureTagPostsController({required String tag}) {
  final tagKey = TagPostsController._normalizeTag(tag);
  TagPostsController._activeTag = tagKey;
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
  final Map<String, GlobalKey> agendaKeys = {};
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
  Map<String, GlobalKey> get _agendaKeys => _state.agendaKeys;
}
