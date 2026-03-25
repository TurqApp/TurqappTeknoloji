part of 'agenda_controller.dart';

class _AgendaControllerState {
  final scrollController = ScrollController();
  final agendaList = <PostsModel>[].obs;
  final mergedFeedEntries = <Map<String, dynamic>>[].obs;
  final filteredFeedEntries = <Map<String, dynamic>>[].obs;
  final renderFeedEntries = <Map<String, dynamic>>[].obs;
  final agendaKeys = <String, GlobalKey>{};
  final showFAB = true.obs;
  final centeredIndex = 0.obs;
  final playbackSuspended = false.obs;
  int? lastCenteredIndex;
  int lastPlaybackRowUpdateIndex = -1;
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
  int agendaRetryCount = 0;
  Worker? mergedFeedWorker;
  Worker? filteredFeedWorker;
  Worker? renderFeedWorker;
  final visibleFractions = <int, double>{};
  final visibleUpdatedAt = <int, DateTime>{};
  String? lastPlaybackWindowSignature;
  String? pendingCenteredDocId;
  int prefetchedThumbnailPostCount = 0;
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
  DateTime? lastEnsureInitialLoadAt;
  DateTime? lastDeferredInitialNetworkBootstrapAt;
  DateTime? lastPlaybackCommandAt;
  DateTime? qaScrollStartedAt;
  double qaScrollStartOffset = 0.0;
  int qaScrollSequence = 0;
  String qaActiveScrollToken = '';
  String qaLatestScrollToken = '';
  String? lastPlaybackCommandDocId;
  bool feedModeFallbackQueued = false;
  int feedModeFallbackEpoch = 0;
}

extension AgendaControllerFieldsPart on AgendaController {
  ScrollController get scrollController => _state.scrollController;
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
  int get _lastPlaybackRowUpdateIndex => _state.lastPlaybackRowUpdateIndex;
  set _lastPlaybackRowUpdateIndex(int value) =>
      _state.lastPlaybackRowUpdateIndex = value;
  RxBool get isMuted => _state.isMuted;
  DocumentSnapshot? get lastDoc => _state.lastDoc;
  set lastDoc(DocumentSnapshot? value) => _state.lastDoc = value;
  bool get _usePrimaryFeedPaging => _state.usePrimaryFeedPaging;
  set _usePrimaryFeedPaging(bool value) => _state.usePrimaryFeedPaging = value;
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
  DateTime? get _lastEnsureInitialLoadAt => _state.lastEnsureInitialLoadAt;
  set _lastEnsureInitialLoadAt(DateTime? value) =>
      _state.lastEnsureInitialLoadAt = value;
  DateTime? get _lastDeferredInitialNetworkBootstrapAt =>
      _state.lastDeferredInitialNetworkBootstrapAt;
  set _lastDeferredInitialNetworkBootstrapAt(DateTime? value) =>
      _state.lastDeferredInitialNetworkBootstrapAt = value;
  DateTime? get _lastPlaybackCommandAt => _state.lastPlaybackCommandAt;
  set _lastPlaybackCommandAt(DateTime? value) =>
      _state.lastPlaybackCommandAt = value;
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
  String? get _lastPlaybackCommandDocId => _state.lastPlaybackCommandDocId;
  set _lastPlaybackCommandDocId(String? value) =>
      _state.lastPlaybackCommandDocId = value;
  bool get _feedModeFallbackQueued => _state.feedModeFallbackQueued;
  set _feedModeFallbackQueued(bool value) =>
      _state.feedModeFallbackQueued = value;
  int get _feedModeFallbackEpoch => _state.feedModeFallbackEpoch;
  set _feedModeFallbackEpoch(int value) => _state.feedModeFallbackEpoch = value;
}
