part of 'top_tags_contoller_library.dart';

class _TopTagsControllerState {
  final navbar = ensureNavBarController();
  final scrollController = ScrollController();
  final tags = <HashtagModel>[].obs;
  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  final visibleIndex = (-1).obs;
  String? pendingCenteredDocId;
  final agendaKeys = <String, GlobalKey>{};
  final agendaList = <PostsModel>[].obs;
  final visibleFractions = <int, double>{};
  final visibleUpdatedAt = <int, DateTime>{};
  Timer? visibilityDebounce;
  Timer? scrollSettleDebounce;
  DateTime? scrollStartedAt;
  double scrollStartOffset = 0.0;
  double lastObservedOffset = 0.0;
  int scrollDirection = 0;
  bool isLoadingMore = false;
  bool hasMore = true;
}

extension TopTagsControllerFieldsPart on _TopTagsControllerBase {
  NavBarController get navbar => _state.navbar;
  ScrollController get scrollController => _state.scrollController;
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
  Map<int, double> get _visibleFractions => _state.visibleFractions;
  Map<int, DateTime> get _visibleUpdatedAt => _state.visibleUpdatedAt;
  Timer? get _visibilityDebounce => _state.visibilityDebounce;
  set _visibilityDebounce(Timer? value) => _state.visibilityDebounce = value;
  Timer? get _scrollSettleDebounce => _state.scrollSettleDebounce;
  set _scrollSettleDebounce(Timer? value) =>
      _state.scrollSettleDebounce = value;
  DateTime? get _scrollStartedAt => _state.scrollStartedAt;
  set _scrollStartedAt(DateTime? value) => _state.scrollStartedAt = value;
  double get _scrollStartOffset => _state.scrollStartOffset;
  set _scrollStartOffset(double value) => _state.scrollStartOffset = value;
  double get _lastObservedOffset => _state.lastObservedOffset;
  set _lastObservedOffset(double value) => _state.lastObservedOffset = value;
  int get _scrollDirection => _state.scrollDirection;
  set _scrollDirection(int value) => _state.scrollDirection = value;
  bool get isLoadingMore => _state.isLoadingMore;
  set isLoadingMore(bool value) => _state.isLoadingMore = value;
  bool get hasMore => _state.hasMore;
  set hasMore(bool value) => _state.hasMore = value;
}
