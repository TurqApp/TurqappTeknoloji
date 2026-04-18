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
  Future<void>? loadNextPageFuture;
  final isLoading = false.obs;
  final hasMore = true.obs;
  final isRefreshing = false.obs;
  QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final followingIDs = <String>{};
  bool preferFreshLaunchIndex = false;
  StreamSubscription? followingSub;
  final authorSummaryCache = LRUCache<String, UserSummary>(
    capacity: 500,
    ttl: const Duration(minutes: 10),
  );
  final userSummaryResolver = UserSummaryResolver.ensure();
  final shortRepository = ensureShortRepository();
  final invariantGuard = ensureRuntimeInvariantGuard();
  final visibilityPolicy = VisibilityPolicyService.ensure();
  bool startupPresentationApplied = false;
  Worker? networkWorker;
  bool renderWindowFrozenOnCellular = false;
  _ShortSessionSourceMode shortSessionSourceMode =
      _ShortSessionSourceMode.unresolved;
  NetworkType? startupNetworkType;
  String? shortOpenTraceToken;
  DateTime? shortOpenTraceStartedAt;
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
  Future<void>? get _loadNextPageFuture => _state.loadNextPageFuture;
  set _loadNextPageFuture(Future<void>? value) =>
      _state.loadNextPageFuture = value;
  int get pageSize => ReadBudgetRegistry.shortHomeInitialLimitValue;
  int get bufferedPageSize => ReadBudgetRegistry.shortBufferedFetchLimit;
  RxBool get isLoading => _state.isLoading;
  RxBool get hasMore => _state.hasMore;
  RxBool get isRefreshing => _state.isRefreshing;
  QueryDocumentSnapshot<Map<String, dynamic>>? get _lastDoc => _state.lastDoc;
  set _lastDoc(QueryDocumentSnapshot<Map<String, dynamic>>? value) =>
      _state.lastDoc = value;
  Set<String> get _followingIDs => _state.followingIDs;
  bool get _preferFreshLaunchIndex => _state.preferFreshLaunchIndex;
  set _preferFreshLaunchIndex(bool value) =>
      _state.preferFreshLaunchIndex = value;
  LRUCache<String, UserSummary> get _authorSummaryCache =>
      _state.authorSummaryCache;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  ShortRepository get _shortRepository => _state.shortRepository;
  RuntimeInvariantGuard get _invariantGuard => _state.invariantGuard;
  VisibilityPolicyService get _visibilityPolicy => _state.visibilityPolicy;
  bool get _startupPresentationApplied => _state.startupPresentationApplied;
  set _startupPresentationApplied(bool value) =>
      _state.startupPresentationApplied = value;
  Worker? get _networkWorker => _state.networkWorker;
  set _networkWorker(Worker? value) => _state.networkWorker = value;
  bool get _renderWindowFrozenOnCellular => _state.renderWindowFrozenOnCellular;
  set _renderWindowFrozenOnCellular(bool value) =>
      _state.renderWindowFrozenOnCellular = value;
  _ShortSessionSourceMode get _shortSessionSourceMode =>
      _state.shortSessionSourceMode;
  set _shortSessionSourceMode(_ShortSessionSourceMode value) =>
      _state.shortSessionSourceMode = value;
  NetworkType? get _shortStartupNetworkType => _state.startupNetworkType;
  set _shortStartupNetworkType(NetworkType? value) =>
      _state.startupNetworkType = value;
  String? get _shortOpenTraceToken => _state.shortOpenTraceToken;
  set _shortOpenTraceToken(String? value) => _state.shortOpenTraceToken = value;
  DateTime? get _shortOpenTraceStartedAt => _state.shortOpenTraceStartedAt;
  set _shortOpenTraceStartedAt(DateTime? value) =>
      _state.shortOpenTraceStartedAt = value;

  void beginShortOpenTrace({
    required String source,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final startedAt = DateTime.now();
    _shortOpenTraceStartedAt = startedAt;
    _shortOpenTraceToken = '${startedAt.microsecondsSinceEpoch}';
    logShortOpenTrace(
      stage: 'tab_tap',
      metadata: <String, dynamic>{
        'source': source,
        ...metadata,
      },
    );
  }

  void logShortOpenTrace({
    required String stage,
    Map<String, dynamic> metadata = const <String, dynamic>{},
  }) {
    final token = _shortOpenTraceToken;
    final startedAt = _shortOpenTraceStartedAt;
    if (token == null || startedAt == null) return;
    final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
    debugPrint(
      '[ShortOpenTrace] token=$token stage=$stage elapsedMs=$elapsedMs '
      'metadata=$metadata',
    );
  }

  int preferredLaunchIndexForCount(int itemCount) {
    if (itemCount <= 0) return 0;
    if (_preferFreshLaunchIndex) return 0;
    return lastIndex.value.clamp(0, itemCount - 1);
  }

  void commitLaunchIndexSelection(int selectedIndex) {
    lastIndex.value = selectedIndex;
    _preferFreshLaunchIndex = false;
  }
}
