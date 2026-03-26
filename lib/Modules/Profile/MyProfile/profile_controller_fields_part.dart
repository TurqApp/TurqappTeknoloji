part of 'profile_controller.dart';

class _ProfileLifecycleState {
  String? activeUid;
  StreamSubscription<User?>? authSub;
  StreamSubscription<Map<String, dynamic>?>? counterSub;
  Timer? persistCacheTimer;
  Worker? allPostsWorker;
  Worker? photosWorker;
  Worker? videosWorker;
  Worker? resharesWorker;
  Worker? scheduledWorker;
  Worker? mergedPostsWorker;
  Worker? postSelectionWorker;
  final postSelection = 0.obs;
}

class _ProfileScrollState {
  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? lastPlaybackCommandDocId;
  DateTime? lastPlaybackCommandAt;
  String? pendingCenteredIdentity;
  final Map<int, double> visibleFractions = <int, double>{};
  Timer? visibilityDebounce;
  final pausetheall = false.obs;
  final showScrollToTop = false.obs;
  final Map<int, ScrollController> scrollControllers =
      <int, ScrollController>{};
  final showPfImage = false.obs;
}

class _ProfileHeaderState {
  final followerCount = 0.obs;
  final followingCount = 0.obs;
  final headerNickname = ''.obs;
  final headerRozet = ''.obs;
  final headerDisplayName = ''.obs;
  final headerAvatarUrl = ''.obs;
  final headerFirstName = ''.obs;
  final headerLastName = ''.obs;
  final headerMeslek = ''.obs;
  final headerBio = ''.obs;
  final headerAdres = ''.obs;
}

class _ProfileFeedState {
  final allPosts = <PostsModel>[].obs;
  final mergedPosts = <Map<String, dynamic>>[].obs;
  DocumentSnapshot? lastPostDoc;
  bool hasMorePosts = true;
  bool isLoadingMore = false;
  DocumentSnapshot<Map<String, dynamic>>? lastPrimaryDoc;
  bool hasMorePrimary = true;
  bool isLoadingPrimary = false;
  final scheduledPosts = <PostsModel>[].obs;
  DocumentSnapshot? lastScheduledDoc;
  bool hasMoreScheduled = true;
  bool isLoadingScheduled = false;
  final photos = <PostsModel>[].obs;
  DocumentSnapshot? lastPostDocPhotos;
  bool hasMorePostsPhotos = true;
  bool isLoadingMorePhotos = false;
  final videos = <PostsModel>[].obs;
  DocumentSnapshot? lastPostDocVideos;
  bool hasMorePostsVideos = true;
  bool isLoadingMoreVideos = false;
  final reshares = <PostsModel>[].obs;
  StreamSubscription<List<UserPostReference>>? resharesSub;
  List<UserPostReference> latestReshareRefs = const [];
  final Map<String, GlobalKey> postKeys = <String, GlobalKey>{};
}

extension ProfileControllerFieldsPart on ProfileController {
  String? get _activeUid => _lifecycleState.activeUid;
  set _activeUid(String? value) => _lifecycleState.activeUid = value;
  StreamSubscription<User?>? get _authSub => _lifecycleState.authSub;
  set _authSub(StreamSubscription<User?>? value) =>
      _lifecycleState.authSub = value;
  StreamSubscription<Map<String, dynamic>?>? get _counterSub =>
      _lifecycleState.counterSub;
  set _counterSub(StreamSubscription<Map<String, dynamic>?>? value) =>
      _lifecycleState.counterSub = value;
  Timer? get _persistCacheTimer => _lifecycleState.persistCacheTimer;
  set _persistCacheTimer(Timer? value) =>
      _lifecycleState.persistCacheTimer = value;
  Worker? get _allPostsWorker => _lifecycleState.allPostsWorker;
  set _allPostsWorker(Worker? value) => _lifecycleState.allPostsWorker = value;
  Worker? get _photosWorker => _lifecycleState.photosWorker;
  set _photosWorker(Worker? value) => _lifecycleState.photosWorker = value;
  Worker? get _videosWorker => _lifecycleState.videosWorker;
  set _videosWorker(Worker? value) => _lifecycleState.videosWorker = value;
  Worker? get _resharesWorker => _lifecycleState.resharesWorker;
  set _resharesWorker(Worker? value) => _lifecycleState.resharesWorker = value;
  Worker? get _scheduledWorker => _lifecycleState.scheduledWorker;
  set _scheduledWorker(Worker? value) =>
      _lifecycleState.scheduledWorker = value;
  Worker? get _mergedPostsWorker => _lifecycleState.mergedPostsWorker;
  set _mergedPostsWorker(Worker? value) =>
      _lifecycleState.mergedPostsWorker = value;
  Worker? get _postSelectionWorker => _lifecycleState.postSelectionWorker;
  set _postSelectionWorker(Worker? value) =>
      _lifecycleState.postSelectionWorker = value;
  RxInt get postSelection => _lifecycleState.postSelection;

  RxInt get currentVisibleIndex => _scrollState.currentVisibleIndex;
  RxInt get centeredIndex => _scrollState.centeredIndex;
  int? get lastCenteredIndex => _scrollState.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _scrollState.lastCenteredIndex = value;
  String? get _lastPlaybackCommandDocId => _scrollState.lastPlaybackCommandDocId;
  set _lastPlaybackCommandDocId(String? value) =>
      _scrollState.lastPlaybackCommandDocId = value;
  DateTime? get _lastPlaybackCommandAt => _scrollState.lastPlaybackCommandAt;
  set _lastPlaybackCommandAt(DateTime? value) =>
      _scrollState.lastPlaybackCommandAt = value;
  String? get _pendingCenteredIdentity => _scrollState.pendingCenteredIdentity;
  set _pendingCenteredIdentity(String? value) =>
      _scrollState.pendingCenteredIdentity = value;
  Map<int, double> get _visibleFractions => _scrollState.visibleFractions;
  Timer? get _visibilityDebounce => _scrollState.visibilityDebounce;
  set _visibilityDebounce(Timer? value) =>
      _scrollState.visibilityDebounce = value;
  RxBool get pausetheall => _scrollState.pausetheall;
  RxBool get showScrollToTop => _scrollState.showScrollToTop;
  Map<int, ScrollController> get _scrollControllers =>
      _scrollState.scrollControllers;
  RxBool get showPfImage => _scrollState.showPfImage;

  RxInt get followerCount => _headerState.followerCount;
  RxInt get followingCount => _headerState.followingCount;
  RxString get headerNickname => _headerState.headerNickname;
  RxString get headerRozet => _headerState.headerRozet;
  RxString get headerDisplayName => _headerState.headerDisplayName;
  RxString get headerAvatarUrl => _headerState.headerAvatarUrl;
  RxString get headerFirstName => _headerState.headerFirstName;
  RxString get headerLastName => _headerState.headerLastName;
  RxString get headerMeslek => _headerState.headerMeslek;
  RxString get headerBio => _headerState.headerBio;
  RxString get headerAdres => _headerState.headerAdres;

  RxList<PostsModel> get allPosts => _feedState.allPosts;
  RxList<Map<String, dynamic>> get mergedPosts => _feedState.mergedPosts;
  DocumentSnapshot? get lastPostDoc => _feedState.lastPostDoc;
  set lastPostDoc(DocumentSnapshot? value) => _feedState.lastPostDoc = value;
  bool get hasMorePosts => _feedState.hasMorePosts;
  set hasMorePosts(bool value) => _feedState.hasMorePosts = value;
  bool get isLoadingMore => _feedState.isLoadingMore;
  set isLoadingMore(bool value) => _feedState.isLoadingMore = value;
  DocumentSnapshot<Map<String, dynamic>>? get _lastPrimaryDoc =>
      _feedState.lastPrimaryDoc;
  set _lastPrimaryDoc(DocumentSnapshot<Map<String, dynamic>>? value) =>
      _feedState.lastPrimaryDoc = value;
  bool get _hasMorePrimary => _feedState.hasMorePrimary;
  set _hasMorePrimary(bool value) => _feedState.hasMorePrimary = value;
  bool get _isLoadingPrimary => _feedState.isLoadingPrimary;
  set _isLoadingPrimary(bool value) => _feedState.isLoadingPrimary = value;
  RxList<PostsModel> get scheduledPosts => _feedState.scheduledPosts;
  DocumentSnapshot? get lastScheduledDoc => _feedState.lastScheduledDoc;
  set lastScheduledDoc(DocumentSnapshot? value) =>
      _feedState.lastScheduledDoc = value;
  bool get hasMoreScheduled => _feedState.hasMoreScheduled;
  set hasMoreScheduled(bool value) => _feedState.hasMoreScheduled = value;
  bool get isLoadingScheduled => _feedState.isLoadingScheduled;
  set isLoadingScheduled(bool value) => _feedState.isLoadingScheduled = value;
  RxList<PostsModel> get photos => _feedState.photos;
  DocumentSnapshot? get lastPostDocPhotos => _feedState.lastPostDocPhotos;
  set lastPostDocPhotos(DocumentSnapshot? value) =>
      _feedState.lastPostDocPhotos = value;
  bool get hasMorePostsPhotos => _feedState.hasMorePostsPhotos;
  set hasMorePostsPhotos(bool value) => _feedState.hasMorePostsPhotos = value;
  bool get isLoadingMorePhotos => _feedState.isLoadingMorePhotos;
  set isLoadingMorePhotos(bool value) => _feedState.isLoadingMorePhotos = value;
  RxList<PostsModel> get videos => _feedState.videos;
  DocumentSnapshot? get lastPostDocVideos => _feedState.lastPostDocVideos;
  set lastPostDocVideos(DocumentSnapshot? value) =>
      _feedState.lastPostDocVideos = value;
  bool get hasMorePostsVideos => _feedState.hasMorePostsVideos;
  set hasMorePostsVideos(bool value) => _feedState.hasMorePostsVideos = value;
  bool get isLoadingMoreVideos => _feedState.isLoadingMoreVideos;
  set isLoadingMoreVideos(bool value) => _feedState.isLoadingMoreVideos = value;
  RxList<PostsModel> get reshares => _feedState.reshares;
  StreamSubscription<List<UserPostReference>>? get _resharesSub =>
      _feedState.resharesSub;
  set _resharesSub(StreamSubscription<List<UserPostReference>>? value) =>
      _feedState.resharesSub = value;
  List<UserPostReference> get _latestReshareRefs =>
      _feedState.latestReshareRefs;
  set _latestReshareRefs(List<UserPostReference> value) =>
      _feedState.latestReshareRefs = value;
  Map<String, GlobalKey> get _postKeys => _feedState.postKeys;
}
