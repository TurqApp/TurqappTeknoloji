part of 'social_profile_controller.dart';

class _SocialProfileStatsState {
  final totalMarket = 0.obs;
  final totalPosts = 0.obs;
  final totalLikes = 0.obs;
  final totalFollower = 0.obs;
  final totalFollowing = 0.obs;
  final postSelection = 0.obs;
  final showPfImage = false.obs;
}

class _SocialProfileScrollState {
  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;
  int? lastCenteredIndex;
  String? pendingCenteredIdentity;
  final Map<int, double> visibleFractions = <int, double>{};
  Timer? visibilityDebounce;
  final scrollController = ScrollController();
  final Map<String, GlobalKey> postKeys = <String, GlobalKey>{};
  final showScrollToTop = false.obs;
}

class _SocialProfileProfileState {
  _SocialProfileProfileState(String userID) : userID = userID;

  String userID;
  final nickname = ''.obs;
  final displayName = ''.obs;
  final avatarUrl = ''.obs;
  final firstName = ''.obs;
  final lastName = ''.obs;
  final token = ''.obs;
  final email = ''.obs;
  final rozet = ''.obs;
  final bio = ''.obs;
  final adres = ''.obs;
  final phoneNumber = ''.obs;
  final mailIzin = false.obs;
  final aramaIzin = false.obs;
  final ban = false.obs;
  final gizliHesap = false.obs;
  final hesapOnayi = false.obs;
  final meslek = ''.obs;
  final blockedUsers = <String>[].obs;
  final complatedCheck = false.obs;
  final takipEdiyorum = false.obs;
  final followLoading = false.obs;
  StoryUserModel? storyUserModel;
  StreamSubscription<Map<String, dynamic>?>? userDocSub;
}

class _SocialProfileFeedState {
  final socialMediaList = <SocialMediaModel>[].obs;
  final reshares = <PostsModel>[].obs;
  StreamSubscription<List<UserPostReference>>? resharesSub;
  final allPosts = <PostsModel>[].obs;
  final photos = <PostsModel>[].obs;
  final scheduledPosts = <PostsModel>[].obs;
  final isLoadingPosts = false.obs;
  final hasMorePosts = true.obs;
  DocumentSnapshot? lastPostDoc;
  DocumentSnapshot<Map<String, dynamic>>? lastPrimaryDoc;
  bool hasMorePrimary = true;
  bool isLoadingPrimary = false;
  final isLoadingPhoto = false.obs;
  final hasMorePhoto = true.obs;
  DocumentSnapshot? lastPostDocPhoto;
  final isLoadingScheduled = false.obs;
  final hasMoreScheduled = true.obs;
  DocumentSnapshot? lastScheduledDoc;
}

extension SocialProfileControllerFieldsPart on SocialProfileController {
  RxInt get totalMarket => _stats.totalMarket;
  RxInt get totalPosts => _stats.totalPosts;
  RxInt get totalLikes => _stats.totalLikes;
  RxInt get totalFollower => _stats.totalFollower;
  RxInt get totalFollowing => _stats.totalFollowing;
  RxInt get postSelection => _stats.postSelection;
  RxBool get showPfImage => _stats.showPfImage;

  RxInt get currentVisibleIndex => _scrollState.currentVisibleIndex;
  RxInt get centeredIndex => _scrollState.centeredIndex;
  int? get lastCenteredIndex => _scrollState.lastCenteredIndex;
  set lastCenteredIndex(int? value) => _scrollState.lastCenteredIndex = value;
  String? get _pendingCenteredIdentity => _scrollState.pendingCenteredIdentity;
  set _pendingCenteredIdentity(String? value) =>
      _scrollState.pendingCenteredIdentity = value;
  Map<int, double> get _visibleFractions => _scrollState.visibleFractions;
  Timer? get _visibilityDebounce => _scrollState.visibilityDebounce;
  set _visibilityDebounce(Timer? value) =>
      _scrollState.visibilityDebounce = value;
  ScrollController get scrollController => _scrollState.scrollController;
  Map<String, GlobalKey> get _postKeys => _scrollState.postKeys;
  RxBool get showScrollToTop => _scrollState.showScrollToTop;

  String get userID => _profileState.userID;
  set userID(String value) => _profileState.userID = value;
  RxString get nickname => _profileState.nickname;
  RxString get displayName => _profileState.displayName;
  RxString get avatarUrl => _profileState.avatarUrl;
  RxString get firstName => _profileState.firstName;
  RxString get lastName => _profileState.lastName;
  RxString get token => _profileState.token;
  RxString get email => _profileState.email;
  RxString get rozet => _profileState.rozet;
  RxString get bio => _profileState.bio;
  RxString get adres => _profileState.adres;
  RxString get phoneNumber => _profileState.phoneNumber;
  RxBool get mailIzin => _profileState.mailIzin;
  RxBool get aramaIzin => _profileState.aramaIzin;
  RxBool get ban => _profileState.ban;
  RxBool get gizliHesap => _profileState.gizliHesap;
  RxBool get hesapOnayi => _profileState.hesapOnayi;
  RxString get meslek => _profileState.meslek;
  RxList<String> get blockedUsers => _profileState.blockedUsers;
  RxBool get complatedCheck => _profileState.complatedCheck;
  RxBool get takipEdiyorum => _profileState.takipEdiyorum;
  RxBool get followLoading => _profileState.followLoading;
  StoryUserModel? get storyUserModel => _profileState.storyUserModel;
  set storyUserModel(StoryUserModel? value) =>
      _profileState.storyUserModel = value;
  StreamSubscription<Map<String, dynamic>?>? get _userDocSub =>
      _profileState.userDocSub;
  set _userDocSub(StreamSubscription<Map<String, dynamic>?>? value) =>
      _profileState.userDocSub = value;

  RxList<SocialMediaModel> get socialMediaList => _feedState.socialMediaList;
  RxList<PostsModel> get reshares => _feedState.reshares;
  StreamSubscription<List<UserPostReference>>? get _resharesSub =>
      _feedState.resharesSub;
  set _resharesSub(StreamSubscription<List<UserPostReference>>? value) =>
      _feedState.resharesSub = value;
  RxList<PostsModel> get allPosts => _feedState.allPosts;
  RxList<PostsModel> get photos => _feedState.photos;
  RxList<PostsModel> get scheduledPosts => _feedState.scheduledPosts;
  RxBool get isLoadingPosts => _feedState.isLoadingPosts;
  RxBool get hasMorePosts => _feedState.hasMorePosts;
  DocumentSnapshot? get lastPostDoc => _feedState.lastPostDoc;
  set lastPostDoc(DocumentSnapshot? value) => _feedState.lastPostDoc = value;
  DocumentSnapshot<Map<String, dynamic>>? get _lastPrimaryDoc =>
      _feedState.lastPrimaryDoc;
  set _lastPrimaryDoc(DocumentSnapshot<Map<String, dynamic>>? value) =>
      _feedState.lastPrimaryDoc = value;
  bool get _hasMorePrimary => _feedState.hasMorePrimary;
  set _hasMorePrimary(bool value) => _feedState.hasMorePrimary = value;
  bool get _isLoadingPrimary => _feedState.isLoadingPrimary;
  set _isLoadingPrimary(bool value) => _feedState.isLoadingPrimary = value;
  RxBool get isLoadingPhoto => _feedState.isLoadingPhoto;
  RxBool get hasMorePhoto => _feedState.hasMorePhoto;
  DocumentSnapshot? get lastPostDocPhoto => _feedState.lastPostDocPhoto;
  set lastPostDocPhoto(DocumentSnapshot? value) =>
      _feedState.lastPostDocPhoto = value;
  RxBool get isLoadingScheduled => _feedState.isLoadingScheduled;
  RxBool get hasMoreScheduled => _feedState.hasMoreScheduled;
  DocumentSnapshot? get lastScheduledDoc => _feedState.lastScheduledDoc;
  set lastScheduledDoc(DocumentSnapshot? value) =>
      _feedState.lastScheduledDoc = value;
}
