part of 'social_profile_followers_controller.dart';

class _SocialProfileFollowersControllerState {
  late String userID;
  final selection = 0.obs;
  late PageController pageController;
  final takipciler = <String>[].obs;
  final takipEdilenler = <String>[].obs;
  final followRepository = ensureFollowRepository();
  final visibilityPolicy = VisibilityPolicyService.ensure();
  bool isLoadingFollowers = false;
  bool isLoadingFollowing = false;
  bool hasMoreFollowers = true;
  bool hasMoreFollowing = true;
}

extension SocialProfileFollowersControllerFieldsPart
    on SocialProfileFollowersController {
  String get userID => _state.userID;
  set userID(String value) => _state.userID = value;
  RxInt get selection => _state.selection;
  PageController get pageController => _state.pageController;
  set pageController(PageController value) => _state.pageController = value;
  RxList<String> get takipciler => _state.takipciler;
  RxList<String> get takipEdilenler => _state.takipEdilenler;
  int get limit => 50;
  FollowRepository get _followRepository => _state.followRepository;
  VisibilityPolicyService get _visibilityPolicy => _state.visibilityPolicy;
  bool get isLoadingFollowers => _state.isLoadingFollowers;
  set isLoadingFollowers(bool value) => _state.isLoadingFollowers = value;
  bool get isLoadingFollowing => _state.isLoadingFollowing;
  set isLoadingFollowing(bool value) => _state.isLoadingFollowing = value;
  bool get hasMoreFollowers => _state.hasMoreFollowers;
  set hasMoreFollowers(bool value) => _state.hasMoreFollowers = value;
  bool get hasMoreFollowing => _state.hasMoreFollowing;
  set hasMoreFollowing(bool value) => _state.hasMoreFollowing = value;
}
