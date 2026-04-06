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
  Timer? startupPromoRevealTimer;
  Timer? startupRenderStageTimer;
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
  Future<void>? headSyncFuture;
  int feedMutationEpoch = 0;
  DateTime? lastEnsureInitialLoadAt;
  DateTime? lastHeadSyncAt;
  DateTime? lastDeferredInitialNetworkBootstrapAt;
  DateTime? lastPlaybackCommandAt;
  DateTime? startupPlaybackLockedAt;
  DateTime? qaScrollStartedAt;
  double qaScrollStartOffset = 0.0;
  int qaScrollSequence = 0;
  String qaActiveScrollToken = '';
  String qaLatestScrollToken = '';
  String? startupLockedFeedDocId;
  String? lastPlaybackCommandDocId;
  bool feedModeFallbackQueued = false;
  int feedModeFallbackEpoch = 0;
  bool feedRefreshInFlight = false;
  bool startupPresentationApplied = false;
  bool startupLiveHeadApplied = false;
  bool startupPromoRevealQueued = false;
  bool startupPromoRevealApplied = false;
  bool startupPromoRevealUnlockedByScroll = false;
  bool startupPromoRevealSawUserDrag = false;
  bool startupRenderStagingActive = false;
  int startupRenderVisiblePostCount = 0;
  final startupCacheOriginVideoDocIds = <String>{};
  final bufferedFeedBlockItems = <PostsModel>[];
  int bufferedFeedBlockBaseCount = 0;
  int nextBufferedFetchTriggerCount =
      ReadBudgetRegistry.feedBufferedFetchLimit;
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
  int? get lastCenteredIndex => _state.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _state.lastCenteredIndex = value;
  String? get _lastPlaybackRowUpdateDocId => _state.lastPlaybackRowUpdateDocId;
  set _lastPlaybackRowUpdateDocId(String? value) =>
      _state.lastPlaybackRowUpdateDocId = value;
  RxBool get isMuted => _state.isMuted;
  DocumentSnapshot? get lastDoc => _state.lastDoc;
  set lastDoc(DocumentSnapshot? value) => _state.lastDoc = value;
  bool get _usePrimaryFeedPaging => _state.usePrimaryFeedPaging;
  set _usePrimaryFeedPaging(bool value) => _state.usePrimaryFeedPaging = value;
  bool get debugUsesPrimaryFeedPaging => _usePrimaryFeedPaging;
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
  Timer? get _startupPromoRevealTimer => _state.startupPromoRevealTimer;
  set _startupPromoRevealTimer(Timer? value) =>
      _state.startupPromoRevealTimer = value;
  Timer? get _startupRenderStageTimer => _state.startupRenderStageTimer;
  set _startupRenderStageTimer(Timer? value) =>
      _state.startupRenderStageTimer = value;
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
  Future<void>? get _headSyncFuture => _state.headSyncFuture;
  set _headSyncFuture(Future<void>? value) => _state.headSyncFuture = value;
  int get _feedMutationEpoch => _state.feedMutationEpoch;
  set _feedMutationEpoch(int value) => _state.feedMutationEpoch = value;
  DateTime? get _lastEnsureInitialLoadAt => _state.lastEnsureInitialLoadAt;
  set _lastEnsureInitialLoadAt(DateTime? value) =>
      _state.lastEnsureInitialLoadAt = value;
  DateTime? get _lastHeadSyncAt => _state.lastHeadSyncAt;
  set _lastHeadSyncAt(DateTime? value) => _state.lastHeadSyncAt = value;
  DateTime? get _lastDeferredInitialNetworkBootstrapAt =>
      _state.lastDeferredInitialNetworkBootstrapAt;
  set _lastDeferredInitialNetworkBootstrapAt(DateTime? value) =>
      _state.lastDeferredInitialNetworkBootstrapAt = value;
  DateTime? get _lastPlaybackCommandAt => _state.lastPlaybackCommandAt;
  set _lastPlaybackCommandAt(DateTime? value) =>
      _state.lastPlaybackCommandAt = value;
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
  bool get _feedModeFallbackQueued => _state.feedModeFallbackQueued;
  set _feedModeFallbackQueued(bool value) =>
      _state.feedModeFallbackQueued = value;
  int get _feedModeFallbackEpoch => _state.feedModeFallbackEpoch;
  set _feedModeFallbackEpoch(int value) => _state.feedModeFallbackEpoch = value;
  bool get _feedRefreshInFlight => _state.feedRefreshInFlight;
  set _feedRefreshInFlight(bool value) => _state.feedRefreshInFlight = value;
  bool get _startupPresentationApplied => _state.startupPresentationApplied;
  set _startupPresentationApplied(bool value) =>
      _state.startupPresentationApplied = value;
  bool get _startupLiveHeadApplied => _state.startupLiveHeadApplied;
  set _startupLiveHeadApplied(bool value) =>
      _state.startupLiveHeadApplied = value;
  bool get _startupPromoRevealQueued => _state.startupPromoRevealQueued;
  set _startupPromoRevealQueued(bool value) =>
      _state.startupPromoRevealQueued = value;
  set _startupPromoRevealApplied(bool value) =>
      _state.startupPromoRevealApplied = value;
  bool get _startupPromoRevealUnlockedByScroll =>
      _state.startupPromoRevealUnlockedByScroll;
  set _startupPromoRevealUnlockedByScroll(bool value) =>
      _state.startupPromoRevealUnlockedByScroll = value;
  bool get _startupPromoRevealSawUserDrag =>
      _state.startupPromoRevealSawUserDrag;
  set _startupPromoRevealSawUserDrag(bool value) =>
      _state.startupPromoRevealSawUserDrag = value;
  bool get _startupRenderStagingActive => _state.startupRenderStagingActive;
  set _startupRenderStagingActive(bool value) =>
      _state.startupRenderStagingActive = value;
  int get _startupRenderVisiblePostCount => _state.startupRenderVisiblePostCount;
  set _startupRenderVisiblePostCount(int value) =>
      _state.startupRenderVisiblePostCount = value;
  Set<String> get _startupCacheOriginVideoDocIds =>
      _state.startupCacheOriginVideoDocIds;
  List<PostsModel> get _bufferedFeedBlockItems => _state.bufferedFeedBlockItems;
  int get _bufferedFeedBlockBaseCount => _state.bufferedFeedBlockBaseCount;
  set _bufferedFeedBlockBaseCount(int value) =>
      _state.bufferedFeedBlockBaseCount = value;
  int get _nextBufferedFetchTriggerCount =>
      _state.nextBufferedFetchTriggerCount;
  set _nextBufferedFetchTriggerCount(int value) =>
      _state.nextBufferedFetchTriggerCount = value;

  bool isStartupCacheOriginVideoDoc(String docId) {
    final normalized = docId.trim();
    if (normalized.isEmpty) return false;
    return _startupCacheOriginVideoDocIds.contains(normalized);
  }
}
