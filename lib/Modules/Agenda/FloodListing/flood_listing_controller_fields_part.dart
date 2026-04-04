part of 'flood_listing_controller.dart';

class _FloodListingControllerState {
  final RxList<PostsModel> floods = <PostsModel>[].obs;
  final ScrollController scrollController = ScrollController();
  final Map<String, GlobalKey> floodKeys = <String, GlobalKey>{};
  final RxInt currentVisibleIndex = RxInt(-1);
  final RxInt centeredIndex = 0.obs;
  final Map<int, double> visibleFractions = <int, double>{};
  final Set<int> promotedSecondSegmentBatchStarts = <int>{};
  Timer? visibilityDebounce;
  int? lastCenteredIndex;
  String? pendingCenteredDocId;
  final PostRepository postRepository = PostRepository.ensure();
}

extension FloodListingControllerFieldsPart on FloodListingController {
  RxList<PostsModel> get floods => _state.floods;
  ScrollController get scrollController => _state.scrollController;
  Map<String, GlobalKey> get _floodKeys => _state.floodKeys;
  RxInt get currentVisibleIndex => _state.currentVisibleIndex;
  RxInt get centeredIndex => _state.centeredIndex;
  Map<int, double> get _visibleFractions => _state.visibleFractions;
  Set<int> get _promotedSecondSegmentBatchStarts =>
      _state.promotedSecondSegmentBatchStarts;
  Timer? get _visibilityDebounce => _state.visibilityDebounce;
  set _visibilityDebounce(Timer? value) => _state.visibilityDebounce = value;
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  String? get _pendingCenteredDocId => _state.pendingCenteredDocId;
  set _pendingCenteredDocId(String? value) =>
      _state.pendingCenteredDocId = value;
  PostRepository get _postRepository => _state.postRepository;
}
