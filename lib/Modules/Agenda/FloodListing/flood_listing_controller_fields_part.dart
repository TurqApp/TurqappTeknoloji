part of 'flood_listing_controller.dart';

class _FloodListingControllerState {
  final RxList<PostsModel> floods = <PostsModel>[].obs;
  final ScrollController scrollController = ScrollController();
  final RxInt currentVisibleIndex = RxInt(-1);
  final RxInt centeredIndex = 0.obs;
  final Map<int, double> visibleFractions = <int, double>{};
  final List<int> playableRawIndices = <int>[];
  final Map<int, int> playableQueueIndexByRawIndex = <int, int>{};
  final Set<int> promotedSecondSegmentBatchStarts = <int>{};
  Timer? priorityPlanTimer;
  Timer? visibilityDebounce;
  Timer? scrollSettleDebounce;
  DateTime? scrollStartedAt;
  double scrollStartOffset = 0.0;
  double lastObservedOffset = 0.0;
  int scrollDirection = 0;
  int? lastCenteredIndex;
  String? pendingCenteredDocId;
}

extension FloodListingControllerFieldsPart on FloodListingController {
  RxList<PostsModel> get floods => _state.floods;
  ScrollController get scrollController => _state.scrollController;
  RxInt get currentVisibleIndex => _state.currentVisibleIndex;
  RxInt get centeredIndex => _state.centeredIndex;
  Map<int, double> get _visibleFractions => _state.visibleFractions;
  List<int> get _playableRawIndices => _state.playableRawIndices;
  Map<int, int> get _playableQueueIndexByRawIndex =>
      _state.playableQueueIndexByRawIndex;
  Set<int> get _promotedSecondSegmentBatchStarts =>
      _state.promotedSecondSegmentBatchStarts;
  Timer? get _priorityPlanTimer => _state.priorityPlanTimer;
  set _priorityPlanTimer(Timer? value) => _state.priorityPlanTimer = value;
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
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  String? get _pendingCenteredDocId => _state.pendingCenteredDocId;
  set _pendingCenteredDocId(String? value) =>
      _state.pendingCenteredDocId = value;
}
