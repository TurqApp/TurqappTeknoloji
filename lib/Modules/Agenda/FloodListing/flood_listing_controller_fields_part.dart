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
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  String? get _pendingCenteredDocId => _state.pendingCenteredDocId;
  set _pendingCenteredDocId(String? value) =>
      _state.pendingCenteredDocId = value;
}
