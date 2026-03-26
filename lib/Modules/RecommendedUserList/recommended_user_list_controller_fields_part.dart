part of 'recommended_user_list_controller.dart';

class _RecommendedUserListControllerState {
  final RxList<RecommendedUserModel> list = <RecommendedUserModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool hasError = false.obs;
  final RxList<String> takipEdilenler = <String>[].obs;
  final VisibilityPolicyService visibilityPolicy =
      VisibilityPolicyService.ensure();
  DocumentSnapshot? lastFollowingDoc;
  bool hasMoreFollowing = true;
  bool isLoadingFollowing = false;
  final int followingLimit = 100;
  final int usersWarmCount = 18;
  final int usersReadyCount = 60;
  final int usersFetchWarm = 80;
  final int usersLimitInitial = 200;
  final int usersLimitFull = 500;
  bool bgScheduled = false;
  bool loadedOnce = false;
  DateTime? lastLoadTime;
  DateTime? lastFollowingLoadTime;
  final Duration cacheValidDuration = const Duration(minutes: 10);
  final Duration followingCacheValidDuration = const Duration(minutes: 30);
}

extension RecommendedUserListControllerFieldsPart
    on RecommendedUserListController {
  RxList<RecommendedUserModel> get list => _state.list;
  RxBool get isLoading => _state.isLoading;
  RxBool get hasError => _state.hasError;
  RxList<String> get takipEdilenler => _state.takipEdilenler;
  VisibilityPolicyService get _visibilityPolicy => _state.visibilityPolicy;
  DocumentSnapshot? get lastFollowingDoc => _state.lastFollowingDoc;
  set lastFollowingDoc(DocumentSnapshot? value) =>
      _state.lastFollowingDoc = value;
  bool get hasMoreFollowing => _state.hasMoreFollowing;
  set hasMoreFollowing(bool value) => _state.hasMoreFollowing = value;
  bool get isLoadingFollowing => _state.isLoadingFollowing;
  set isLoadingFollowing(bool value) => _state.isLoadingFollowing = value;
  int get followingLimit => _state.followingLimit;
  int get usersWarmCount => _state.usersWarmCount;
  int get usersReadyCount => _state.usersReadyCount;
  int get usersFetchWarm => _state.usersFetchWarm;
  int get usersLimitInitial => _state.usersLimitInitial;
  int get usersLimitFull => _state.usersLimitFull;
  bool get _bgScheduled => _state.bgScheduled;
  set _bgScheduled(bool value) => _state.bgScheduled = value;
  bool get loadedOnce => _state.loadedOnce;
  set loadedOnce(bool value) => _state.loadedOnce = value;
  DateTime? get _lastLoadTime => _state.lastLoadTime;
  set _lastLoadTime(DateTime? value) => _state.lastLoadTime = value;
  DateTime? get _lastFollowingLoadTime => _state.lastFollowingLoadTime;
  set _lastFollowingLoadTime(DateTime? value) =>
      _state.lastFollowingLoadTime = value;
  Duration get _cacheValidDuration => _state.cacheValidDuration;
  Duration get _followingCacheValidDuration =>
      _state.followingCacheValidDuration;
}
