part of 'following_followers_controller.dart';

class _FollowingFollowersControllerState {
  final userSummaryResolver = UserSummaryResolver.ensure();
  final followRepository = FollowRepository.ensure();
  final visibilityPolicy = VisibilityPolicyService.ensure();
  final selection = 0.obs;
  final pageController = PageController();
  final takipciler = <String>[].obs;
  final takipEdilenler = <String>[].obs;
  bool isLoadingFollowers = false;
  bool isLoadingFollowing = false;
  bool hasMoreFollowers = true;
  bool hasMoreFollowing = true;
  final takipciCounter = 0.obs;
  final takipedilenCounter = 0.obs;
  final searchTakipciController = TextEditingController();
  final searchTakipEdilenController = TextEditingController();
  final relationIdSetCache = <String, _RelationIdSetCacheEntry>{};
  final searchResultCache = <String, _SearchResultCacheEntry>{};
  final nickname = ''.obs;
}

extension FollowingFollowersControllerFieldsPart
    on FollowingFollowersController {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  FollowRepository get _followRepository => _state.followRepository;
  VisibilityPolicyService get _visibilityPolicy => _state.visibilityPolicy;
  RxInt get selection => _state.selection;
  PageController get pageController => _state.pageController;
  RxList<String> get takipciler => _state.takipciler;
  RxList<String> get takipEdilenler => _state.takipEdilenler;
  bool get isLoadingFollowers => _state.isLoadingFollowers;
  set isLoadingFollowers(bool value) => _state.isLoadingFollowers = value;
  bool get isLoadingFollowing => _state.isLoadingFollowing;
  set isLoadingFollowing(bool value) => _state.isLoadingFollowing = value;
  bool get hasMoreFollowers => _state.hasMoreFollowers;
  set hasMoreFollowers(bool value) => _state.hasMoreFollowers = value;
  bool get hasMoreFollowing => _state.hasMoreFollowing;
  set hasMoreFollowing(bool value) => _state.hasMoreFollowing = value;
  RxInt get takipciCounter => _state.takipciCounter;
  RxInt get takipedilenCounter => _state.takipedilenCounter;
  TextEditingController get searchTakipciController =>
      _state.searchTakipciController;
  TextEditingController get searchTakipEdilenController =>
      _state.searchTakipEdilenController;
  Map<String, _RelationIdSetCacheEntry> get _relationIdSetCache =>
      _state.relationIdSetCache;
  Map<String, _SearchResultCacheEntry> get _searchResultCache =>
      _state.searchResultCache;
  RxString get nickname => _state.nickname;
}
