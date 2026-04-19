part of 'agenda_controller.dart';

class _AgendaControllerState {
  final scrollController = ScrollController();
  final agendaFeedApplicationService = AgendaFeedApplicationService();
  final agendaList = <PostsModel>[].obs;
  final mergedFeedEntries = <Map<String, dynamic>>[].obs;
  final filteredFeedEntries = <Map<String, dynamic>>[].obs;
  final renderFeedEntries = <Map<String, dynamic>>[].obs;
  final agendaKeys = <String, GlobalKey>{};
  final showFAB = true.obs;
  final centeredIndex = 0.obs;
  final playbackSuspended = false.obs;
  final feedWarmPreloadAnchorKey = ''.obs;
  final startupWarmPreloadDocIds = <String>[].obs;
  final startupWarmPreloadPreparedDocIds = <String>{};
  int? lastCenteredIndex;
  String? lastPlaybackRowUpdateDocId;
  final isMuted = false.obs;
  DocumentSnapshot? lastDoc;
  bool usePrimaryFeedPaging = true;
  final hasMore = true.obs;
  final isLoading = false.obs;
  final pauseAll = false.obs;
  NavBarController? navBarController;
  final highlightDocIDs = <String>{}.obs;
  Timer? visibilityDebounce;
  Timer? feedPrefetchDebounce;
  Timer? scrollIdleDebounce;
  Timer? playbackReassertTimer;
  Timer? reshareWarmupTimer;
  Timer? resharePostsFetchTimer;
  Timer? agendaRetryTimer;
  Timer? deferredInitialNetworkBootstrapTimer;
  Timer? startupWarmPreloadFallbackTimer;
  Timer? startupWarmPreloadReleaseTimer;
  Timer? growthRenderReleaseTimer;
  int agendaRetryCount = 0;
  Worker? mergedFeedWorker;
  Worker? filteredFeedWorker;
  Worker? renderFeedWorker;
  final visibleFractions = <int, double>{};
  final visibleUpdatedAt = <int, DateTime>{};
  String? lastPlaybackWindowSignature;
  String? pendingCenteredDocId;
  int prefetchedThumbnailPostCount = 0;
  final prefetchedThumbnailDocIds = <String>{};
  final followingIDs = <String>{}.obs;
  final feedViewMode = FeedViewMode.forYou.obs;
  final myReshares = <String, int>{}.obs;
  final publicReshareEvents = <Map<String, dynamic>>[].obs;
  final feedReshareEntries = <Map<String, dynamic>>[].obs;
  final userPrivacyCache = <String, bool>{};
  final userDeactivatedCache = <String, bool>{};
  List<String> hiddenPosts = <String>[];
  double lastOffset = 0.0;
  bool ensureInitialLoadInFlight = false;
  Future<void>? ensureInitialLoadFuture;
  Future<void>? surfaceBootstrapFuture;
  Future<void>? startupPrepareFuture;
  int feedMutationEpoch = 0;
  DateTime? lastEnsureInitialLoadAt;
  DateTime? lastFeedAuthUnavailableAt;
  DateTime? lastPlaybackCommandAt;
  DateTime? lastFloodRootWarmAt;
  DateTime? startupPlaybackLockedAt;
  DateTime? qaScrollStartedAt;
  double qaScrollStartOffset = 0.0;
  int qaScrollSequence = 0;
  String qaActiveScrollToken = '';
  String qaLatestScrollToken = '';
  String? startupLockedFeedDocId;
  String? lastPlaybackCommandDocId;
  String? lastFloodRootWarmDocId;
  String? startupWarmPreloadPrimaryDocId;
  bool feedModeFallbackQueued = false;
  int feedModeFallbackEpoch = 0;
  bool feedRefreshInFlight = false;
  int lastFeedWarmGroupIndex = -1;
  int lastFeedWarmBlockIndex = -1;
  bool startupPlannerHeadApplied = false;
  bool startupHeadFinalized = false;
  bool startupRenderBootstrapHold = false;
  bool growthRenderAppendHold = false;
  bool connectedFeedReservoirWarmInFlight = false;
  bool connectedFeedStageFourReadyCheckpointLogged = false;
  int growthRenderAppendEpoch = 0;
  int connectedFeedReservoirWarmTarget = 0;
  int deferredInitialNetworkBootstrapToken = 0;
  final startupCacheOriginVideoDocIds = <String>{};
  int nextPageFetchTriggerCount = ReadBudgetRegistry.feedPageFetchLimit;
  final plannedColdFeedWindow = <PostsModel>[];
  int? feedTypesenseNextPage;
  DocumentSnapshot<Map<String, dynamic>>? plannedColdFeedLastDoc;
  bool plannedColdFeedUsesPrimaryFeed = true;
  int? plannedColdFeedNextTypesensePage;
  Worker? networkWorker;
  bool renderWindowFrozenOnCellular = false;
  NetworkType? lastStartupSurfacePreparedNetwork;
  int lastStartupSurfacePreparedMutationEpoch = -1;
  int lastPrimarySurfaceVisibleMutationEpoch = -1;
}

extension AgendaControllerFieldsPart on AgendaController {
  ScrollController get scrollController => _state.scrollController;
  AgendaFeedApplicationService get _agendaFeedApplicationService =>
      _state.agendaFeedApplicationService;
  RxList<PostsModel> get agendaList => _state.agendaList;
  RxList<Map<String, dynamic>> get mergedFeedEntries =>
      _state.mergedFeedEntries;
  RxList<Map<String, dynamic>> get filteredFeedEntries =>
      _state.filteredFeedEntries;
  RxList<Map<String, dynamic>> get renderFeedEntries =>
      _state.renderFeedEntries;
  Map<String, GlobalKey> get _agendaKeys => _state.agendaKeys;
  RxBool get showFAB => _state.showFAB;
  RxInt get centeredIndex => _state.centeredIndex;
  RxBool get playbackSuspended => _state.playbackSuspended;
  RxString get feedWarmPreloadAnchorKeyRx => _state.feedWarmPreloadAnchorKey;
  RxList<String> get startupWarmPreloadDocIdsRx =>
      _state.startupWarmPreloadDocIds;
  List<String> get startupWarmPreloadDocIds =>
      _state.startupWarmPreloadDocIds.toList(growable: false);
  String get feedWarmPreloadAnchorKey => _state.feedWarmPreloadAnchorKey.value;
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  String? get _lastPlaybackRowUpdateDocId => _state.lastPlaybackRowUpdateDocId;
  set _lastPlaybackRowUpdateDocId(String? value) =>
      _state.lastPlaybackRowUpdateDocId = value;
  RxBool get isMuted => _state.isMuted;
  DocumentSnapshot? get lastDoc => _state.lastDoc;
  set lastDoc(DocumentSnapshot? value) => _state.lastDoc = value;
  int? get _feedTypesenseNextPage => _state.feedTypesenseNextPage;
  set _feedTypesenseNextPage(int? value) =>
      _state.feedTypesenseNextPage = value;
  bool get _usePrimaryFeedPaging => _state.usePrimaryFeedPaging;
  set _usePrimaryFeedPaging(bool value) => _state.usePrimaryFeedPaging = value;
  bool get debugUsesPrimaryFeedPaging => _usePrimaryFeedPaging;
  bool get debugFeedIsLoading => isLoading.value;
  bool get debugEnsureInitialLoadInFlight => _ensureInitialLoadInFlight;
  bool get debugSurfaceBootstrapInFlight => _surfaceBootstrapFuture != null;
  bool get debugStartupHeadFinalized => _startupHeadFinalized;
  int get debugPlannedColdFeedCount => _plannedColdFeedWindow.length;
  int get debugRemainingPlannedColdFeedCount {
    final seenDocIds = <String>{
      for (final post in agendaList)
        if (post.docID.trim().isNotEmpty) post.docID.trim(),
    };
    return _remainingPlannedColdFeedCount(seenDocIds: seenDocIds);
  }

  int? get debugPlannedColdFeedNextTypesensePage =>
      _plannedColdFeedNextTypesensePage;
  bool get startupRenderBootstrapHold => _startupRenderBootstrapHold;
  RxBool get hasMore => _state.hasMore;
  RxBool get isLoading => _state.isLoading;
  RxBool get pauseAll => _state.pauseAll;
  NavBarController get navBarController => _state.navBarController!;
  set navBarController(NavBarController value) =>
      _state.navBarController = value;
  RxSet<String> get highlightDocIDs => _state.highlightDocIDs;
  Timer? get _visibilityDebounce => _state.visibilityDebounce;
  set _visibilityDebounce(Timer? value) => _state.visibilityDebounce = value;
  Timer? get _feedPrefetchDebounce => _state.feedPrefetchDebounce;
  set _feedPrefetchDebounce(Timer? value) =>
      _state.feedPrefetchDebounce = value;
  Timer? get _scrollIdleDebounce => _state.scrollIdleDebounce;
  set _scrollIdleDebounce(Timer? value) => _state.scrollIdleDebounce = value;
  Timer? get _playbackReassertTimer => _state.playbackReassertTimer;
  set _playbackReassertTimer(Timer? value) =>
      _state.playbackReassertTimer = value;
  Timer? get _reshareWarmupTimer => _state.reshareWarmupTimer;
  set _reshareWarmupTimer(Timer? value) => _state.reshareWarmupTimer = value;
  Timer? get _resharePostsFetchTimer => _state.resharePostsFetchTimer;
  set _resharePostsFetchTimer(Timer? value) =>
      _state.resharePostsFetchTimer = value;
  Timer? get _agendaRetryTimer => _state.agendaRetryTimer;
  set _agendaRetryTimer(Timer? value) => _state.agendaRetryTimer = value;
  Timer? get _deferredInitialNetworkBootstrapTimer =>
      _state.deferredInitialNetworkBootstrapTimer;
  set _deferredInitialNetworkBootstrapTimer(Timer? value) =>
      _state.deferredInitialNetworkBootstrapTimer = value;
  Timer? get _startupWarmPreloadFallbackTimer =>
      _state.startupWarmPreloadFallbackTimer;
  set _startupWarmPreloadFallbackTimer(Timer? value) =>
      _state.startupWarmPreloadFallbackTimer = value;
  Timer? get _startupWarmPreloadReleaseTimer =>
      _state.startupWarmPreloadReleaseTimer;
  set _startupWarmPreloadReleaseTimer(Timer? value) =>
      _state.startupWarmPreloadReleaseTimer = value;
  Timer? get _growthRenderReleaseTimer => _state.growthRenderReleaseTimer;
  set _growthRenderReleaseTimer(Timer? value) =>
      _state.growthRenderReleaseTimer = value;
  int get _agendaRetryCount => _state.agendaRetryCount;
  set _agendaRetryCount(int value) => _state.agendaRetryCount = value;
  Worker? get _mergedFeedWorker => _state.mergedFeedWorker;
  set _mergedFeedWorker(Worker? value) => _state.mergedFeedWorker = value;
  Worker? get _filteredFeedWorker => _state.filteredFeedWorker;
  set _filteredFeedWorker(Worker? value) => _state.filteredFeedWorker = value;
  Worker? get _renderFeedWorker => _state.renderFeedWorker;
  set _renderFeedWorker(Worker? value) => _state.renderFeedWorker = value;
  Map<int, double> get _visibleFractions => _state.visibleFractions;
  Map<int, DateTime> get _visibleUpdatedAt => _state.visibleUpdatedAt;
  String? get _lastPlaybackWindowSignature =>
      _state.lastPlaybackWindowSignature;
  set _lastPlaybackWindowSignature(String? value) =>
      _state.lastPlaybackWindowSignature = value;

  void markFeedWarmPreloadAnchorReady(String playbackHandleKey) {
    final normalized = playbackHandleKey.trim();
    if (normalized.isEmpty) return;
    if (_state.feedWarmPreloadAnchorKey.value == normalized) return;
    _state.feedWarmPreloadAnchorKey.value = normalized;
  }

  String? get _pendingCenteredDocId => _state.pendingCenteredDocId;
  set _pendingCenteredDocId(String? value) =>
      _state.pendingCenteredDocId = value;
  int get _prefetchedThumbnailPostCount => _state.prefetchedThumbnailPostCount;
  set _prefetchedThumbnailPostCount(int value) =>
      _state.prefetchedThumbnailPostCount = value;
  Set<String> get _prefetchedThumbnailDocIds =>
      _state.prefetchedThumbnailDocIds;
  RxSet<String> get followingIDs => _state.followingIDs;
  Rx<FeedViewMode> get feedViewMode => _state.feedViewMode;
  RxMap<String, int> get myReshares => _state.myReshares;
  RxList<Map<String, dynamic>> get publicReshareEvents =>
      _state.publicReshareEvents;
  RxList<Map<String, dynamic>> get feedReshareEntries =>
      _state.feedReshareEntries;
  Map<String, bool> get _userPrivacyCache => _state.userPrivacyCache;
  Map<String, bool> get _userDeactivatedCache => _state.userDeactivatedCache;
  List<String> get hiddenPosts => _state.hiddenPosts;
  set hiddenPosts(List<String> value) => _state.hiddenPosts = value;
  double get lastOffset => _state.lastOffset;
  set lastOffset(double value) => _state.lastOffset = value;
  bool get _ensureInitialLoadInFlight => _state.ensureInitialLoadInFlight;
  set _ensureInitialLoadInFlight(bool value) =>
      _state.ensureInitialLoadInFlight = value;
  Future<void>? get _ensureInitialLoadFuture => _state.ensureInitialLoadFuture;
  set _ensureInitialLoadFuture(Future<void>? value) =>
      _state.ensureInitialLoadFuture = value;
  Future<void>? get _surfaceBootstrapFuture => _state.surfaceBootstrapFuture;
  set _surfaceBootstrapFuture(Future<void>? value) =>
      _state.surfaceBootstrapFuture = value;
  Future<void>? get _startupPrepareFuture => _state.startupPrepareFuture;
  set _startupPrepareFuture(Future<void>? value) =>
      _state.startupPrepareFuture = value;
  int get _feedMutationEpoch => _state.feedMutationEpoch;
  set _feedMutationEpoch(int value) => _state.feedMutationEpoch = value;
  DateTime? get _lastEnsureInitialLoadAt => _state.lastEnsureInitialLoadAt;
  set _lastEnsureInitialLoadAt(DateTime? value) =>
      _state.lastEnsureInitialLoadAt = value;
  DateTime? get _lastFeedAuthUnavailableAt => _state.lastFeedAuthUnavailableAt;
  set _lastFeedAuthUnavailableAt(DateTime? value) =>
      _state.lastFeedAuthUnavailableAt = value;
  DateTime? get _lastPlaybackCommandAt => _state.lastPlaybackCommandAt;
  set _lastPlaybackCommandAt(DateTime? value) =>
      _state.lastPlaybackCommandAt = value;
  DateTime? get _lastFloodRootWarmAt => _state.lastFloodRootWarmAt;
  set _lastFloodRootWarmAt(DateTime? value) =>
      _state.lastFloodRootWarmAt = value;
  Set<String> get _startupWarmPreloadPreparedDocIds =>
      _state.startupWarmPreloadPreparedDocIds;
  DateTime? get _startupPlaybackLockedAt => _state.startupPlaybackLockedAt;
  set _startupPlaybackLockedAt(DateTime? value) =>
      _state.startupPlaybackLockedAt = value;
  DateTime? get _qaScrollStartedAt => _state.qaScrollStartedAt;
  set _qaScrollStartedAt(DateTime? value) => _state.qaScrollStartedAt = value;
  double get _qaScrollStartOffset => _state.qaScrollStartOffset;
  set _qaScrollStartOffset(double value) => _state.qaScrollStartOffset = value;
  int get _qaScrollSequence => _state.qaScrollSequence;
  set _qaScrollSequence(int value) => _state.qaScrollSequence = value;
  String get _qaActiveScrollToken => _state.qaActiveScrollToken;
  set _qaActiveScrollToken(String value) => _state.qaActiveScrollToken = value;
  String get _qaLatestScrollToken => _state.qaLatestScrollToken;
  set _qaLatestScrollToken(String value) => _state.qaLatestScrollToken = value;
  String? get _startupLockedFeedDocId => _state.startupLockedFeedDocId;
  set _startupLockedFeedDocId(String? value) =>
      _state.startupLockedFeedDocId = value;
  String? get _lastPlaybackCommandDocId => _state.lastPlaybackCommandDocId;
  set _lastPlaybackCommandDocId(String? value) =>
      _state.lastPlaybackCommandDocId = value;
  String? get _lastFloodRootWarmDocId => _state.lastFloodRootWarmDocId;
  set _lastFloodRootWarmDocId(String? value) =>
      _state.lastFloodRootWarmDocId = value;
  bool get _feedModeFallbackQueued => _state.feedModeFallbackQueued;
  set _feedModeFallbackQueued(bool value) =>
      _state.feedModeFallbackQueued = value;
  int get _feedModeFallbackEpoch => _state.feedModeFallbackEpoch;
  set _feedModeFallbackEpoch(int value) => _state.feedModeFallbackEpoch = value;
  bool get _feedRefreshInFlight => _state.feedRefreshInFlight;
  set _feedRefreshInFlight(bool value) => _state.feedRefreshInFlight = value;
  int get _lastFeedWarmGroupIndex => _state.lastFeedWarmGroupIndex;
  set _lastFeedWarmGroupIndex(int value) =>
      _state.lastFeedWarmGroupIndex = value;
  int get _lastFeedWarmBlockIndex => _state.lastFeedWarmBlockIndex;
  set _lastFeedWarmBlockIndex(int value) =>
      _state.lastFeedWarmBlockIndex = value;
  bool get _startupPlannerHeadApplied => _state.startupPlannerHeadApplied;
  set _startupPlannerHeadApplied(bool value) =>
      _state.startupPlannerHeadApplied = value;
  bool get _startupHeadFinalized => _state.startupHeadFinalized;
  set _startupHeadFinalized(bool value) => _state.startupHeadFinalized = value;
  bool get _startupRenderBootstrapHold => _state.startupRenderBootstrapHold;
  set _startupRenderBootstrapHold(bool value) =>
      _state.startupRenderBootstrapHold = value;
  bool get _growthRenderAppendHold => _state.growthRenderAppendHold;
  set _growthRenderAppendHold(bool value) =>
      _state.growthRenderAppendHold = value;
  bool get _connectedFeedReservoirWarmInFlight =>
      _state.connectedFeedReservoirWarmInFlight;
  set _connectedFeedReservoirWarmInFlight(bool value) =>
      _state.connectedFeedReservoirWarmInFlight = value;
  bool get _connectedFeedStageFourReadyCheckpointLogged =>
      _state.connectedFeedStageFourReadyCheckpointLogged;
  set _connectedFeedStageFourReadyCheckpointLogged(bool value) =>
      _state.connectedFeedStageFourReadyCheckpointLogged = value;
  int get _growthRenderAppendEpoch => _state.growthRenderAppendEpoch;
  set _growthRenderAppendEpoch(int value) =>
      _state.growthRenderAppendEpoch = value;
  int get _connectedFeedReservoirWarmTarget =>
      _state.connectedFeedReservoirWarmTarget;
  set _connectedFeedReservoirWarmTarget(int value) =>
      _state.connectedFeedReservoirWarmTarget = value;
  String? get _startupWarmPreloadPrimaryDocId =>
      _state.startupWarmPreloadPrimaryDocId;
  set _startupWarmPreloadPrimaryDocId(String? value) =>
      _state.startupWarmPreloadPrimaryDocId = value;
  int get _deferredInitialNetworkBootstrapToken =>
      _state.deferredInitialNetworkBootstrapToken;
  set _deferredInitialNetworkBootstrapToken(int value) =>
      _state.deferredInitialNetworkBootstrapToken = value;
  Set<String> get _startupCacheOriginVideoDocIds =>
      _state.startupCacheOriginVideoDocIds;
  int get _nextPageFetchTriggerCount => _state.nextPageFetchTriggerCount;
  set _nextPageFetchTriggerCount(int value) =>
      _state.nextPageFetchTriggerCount = value;
  List<PostsModel> get _plannedColdFeedWindow => _state.plannedColdFeedWindow;
  DocumentSnapshot<Map<String, dynamic>>? get _plannedColdFeedLastDoc =>
      _state.plannedColdFeedLastDoc;
  set _plannedColdFeedLastDoc(DocumentSnapshot<Map<String, dynamic>>? value) =>
      _state.plannedColdFeedLastDoc = value;
  bool get _plannedColdFeedUsesPrimaryFeed =>
      _state.plannedColdFeedUsesPrimaryFeed;
  set _plannedColdFeedUsesPrimaryFeed(bool value) =>
      _state.plannedColdFeedUsesPrimaryFeed = value;
  int? get _plannedColdFeedNextTypesensePage =>
      _state.plannedColdFeedNextTypesensePage;
  set _plannedColdFeedNextTypesensePage(int? value) =>
      _state.plannedColdFeedNextTypesensePage = value;
  Worker? get _networkWorker => _state.networkWorker;
  set _networkWorker(Worker? value) => _state.networkWorker = value;
  bool get _renderWindowFrozenOnCellular => _state.renderWindowFrozenOnCellular;
  set _renderWindowFrozenOnCellular(bool value) =>
      _state.renderWindowFrozenOnCellular = value;
  NetworkType? get _lastStartupSurfacePreparedNetwork =>
      _state.lastStartupSurfacePreparedNetwork;
  set _lastStartupSurfacePreparedNetwork(NetworkType? value) =>
      _state.lastStartupSurfacePreparedNetwork = value;
  int get _lastStartupSurfacePreparedMutationEpoch =>
      _state.lastStartupSurfacePreparedMutationEpoch;
  set _lastStartupSurfacePreparedMutationEpoch(int value) =>
      _state.lastStartupSurfacePreparedMutationEpoch = value;
  int get _lastPrimarySurfaceVisibleMutationEpoch =>
      _state.lastPrimarySurfaceVisibleMutationEpoch;
  set _lastPrimarySurfaceVisibleMutationEpoch(int value) =>
      _state.lastPrimarySurfaceVisibleMutationEpoch = value;

  bool isStartupCacheOriginVideoDoc(String docId) {
    final normalized = docId.trim();
    if (normalized.isEmpty) return false;
    return _startupCacheOriginVideoDocIds.contains(normalized);
  }
}
