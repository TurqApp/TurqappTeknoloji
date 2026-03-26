part of 'top_tags_contoller.dart';

class _TopTagsControllerState {
  final navbar = ensureNavBarController();
  final scrollController = ScrollController();
  double lastOffset = 0;
  final tags = <HashtagModel>[].obs;
  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  final visibleIndex = (-1).obs;
  String? pendingCenteredDocId;
  final agendaKeys = <String, GlobalKey>{};
  final agendaList = <PostsModel>[].obs;
  bool isLoadingMore = false;
  bool hasMore = true;
}

extension TopTagsControllerFieldsPart on TopTagsController {
  NavBarController get navbar => _state.navbar;
  ScrollController get scrollController => _state.scrollController;
  double get _lastOffset => _state.lastOffset;
  set _lastOffset(double value) => _state.lastOffset = value;
  RxList<HashtagModel> get tags => _state.tags;
  RxInt get currentVisibleIndex => _state.currentVisibleIndex;
  RxInt get centeredIndex => _state.centeredIndex;
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  RxInt get visibleIndex => _state.visibleIndex;
  String? get _pendingCenteredDocId => _state.pendingCenteredDocId;
  set _pendingCenteredDocId(String? value) =>
      _state.pendingCenteredDocId = value;
  Map<String, GlobalKey> get _agendaKeys => _state.agendaKeys;
  RxList<PostsModel> get agendaList => _state.agendaList;
  bool get isLoadingMore => _state.isLoadingMore;
  set isLoadingMore(bool value) => _state.isLoadingMore = value;
  bool get hasMore => _state.hasMore;
  set hasMore(bool value) => _state.hasMore = value;
}
