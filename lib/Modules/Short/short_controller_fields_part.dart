part of 'short_controller.dart';

class _ShortControllerState {
  final shorts = <PostsModel>[].obs;
  final shortFeedApplicationService = ShortFeedApplicationService();
  final videoPool = ensureGlobalVideoAdapterPool();
  final playbackCoordinator = ShortPlaybackCoordinator.forCurrentPlatform();
  final playbackRuntimeService = const PlaybackRuntimeService();
  final cache = <int, HLSVideoAdapter>{};
  final tiers = <int, _CacheTier>{};
  final lastIndex = 0.obs;
  Future<void>? backgroundPreloadFuture;
  Future<void>? initialLoadFuture;
  Future<void>? startupPrepareFuture;
  final isLoading = false.obs;
  final hasMore = true.obs;
  final isRefreshing = false.obs;
  QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final followingIDs = <String>{};
  StreamSubscription? followingSub;
  final authorSummaryCache = LRUCache<String, UserSummary>(
    capacity: 500,
    ttl: const Duration(minutes: 10),
  );
  final userSummaryResolver = UserSummaryResolver.ensure();
  final shortRepository = ensureShortRepository();
  final shortSnapshotRepository = ensureShortSnapshotRepository();
  final invariantGuard = ensureRuntimeInvariantGuard();
  final visibilityPolicy = VisibilityPolicyService.ensure();
  bool startupPresentationApplied = false;
}

extension ShortControllerFieldsPart on ShortController {
  RxList<PostsModel> get shorts => _state.shorts;
  ShortFeedApplicationService get _shortFeedApplicationService =>
      _state.shortFeedApplicationService;
  GlobalVideoAdapterPool get _videoPool => _state.videoPool;
  ShortPlaybackCoordinator get _playbackCoordinator =>
      _state.playbackCoordinator;
  PlaybackRuntimeService get _playbackRuntimeService =>
      _state.playbackRuntimeService;
  Map<int, HLSVideoAdapter> get cache => _state.cache;
  Map<int, _CacheTier> get _tiers => _state.tiers;
  RxInt get lastIndex => _state.lastIndex;
  Future<void>? get _backgroundPreloadFuture => _state.backgroundPreloadFuture;
  set _backgroundPreloadFuture(Future<void>? value) =>
      _state.backgroundPreloadFuture = value;
  Future<void>? get _initialLoadFuture => _state.initialLoadFuture;
  set _initialLoadFuture(Future<void>? value) =>
      _state.initialLoadFuture = value;
  Future<void>? get _startupPrepareFuture => _state.startupPrepareFuture;
  set _startupPrepareFuture(Future<void>? value) =>
      _state.startupPrepareFuture = value;
  int get pageSize => ReadBudgetRegistry.shortHomeInitialLimitValue;
  int get bufferedPageSize => ReadBudgetRegistry.shortBufferedFetchLimit;
  RxBool get isLoading => _state.isLoading;
  RxBool get hasMore => _state.hasMore;
  RxBool get isRefreshing => _state.isRefreshing;
  QueryDocumentSnapshot<Map<String, dynamic>>? get _lastDoc => _state.lastDoc;
  set _lastDoc(QueryDocumentSnapshot<Map<String, dynamic>>? value) =>
      _state.lastDoc = value;
  Set<String> get _followingIDs => _state.followingIDs;
  LRUCache<String, UserSummary> get _authorSummaryCache =>
      _state.authorSummaryCache;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  ShortRepository get _shortRepository => _state.shortRepository;
  ShortSnapshotRepository get _shortSnapshotRepository =>
      _state.shortSnapshotRepository;
  RuntimeInvariantGuard get _invariantGuard => _state.invariantGuard;
  VisibilityPolicyService get _visibilityPolicy => _state.visibilityPolicy;
  bool get _startupPresentationApplied => _state.startupPresentationApplied;
  set _startupPresentationApplied(bool value) =>
      _state.startupPresentationApplied = value;
}
