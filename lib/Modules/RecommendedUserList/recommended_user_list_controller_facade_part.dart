part of 'recommended_user_list_controller.dart';

RecommendedUserListController? maybeFindRecommendedUserListController() {
  final isRegistered = Get.isRegistered<RecommendedUserListController>();
  if (!isRegistered) return null;
  return Get.find<RecommendedUserListController>();
}

RecommendedUserListController ensureRecommendedUserListController() {
  final existing = maybeFindRecommendedUserListController();
  if (existing != null) return existing;
  return Get.put(RecommendedUserListController());
}

extension RecommendedUserListControllerFacadePart
    on RecommendedUserListController {
  void reshuffleLocal() {
    final copy = List<RecommendedUserModel>.from(list);
    copy.shuffle();
    list.assignAll(copy);
  }

  Future<void> refreshUsers() async {
    lastFollowingDoc = null;
    hasMoreFollowing = true;
    isLoadingFollowing = false;
    takipEdilenler.clear();
    _lastLoadTime = null;
    _lastFollowingLoadTime = null;
    hasError.value = false;
    await getUsers();
  }

  Future<void> getFollowing() =>
      _RecommendedUserListControllerRuntimeX(this).getFollowing();

  Future<void> getUsers({int? limit}) =>
      _RecommendedUserListControllerRuntimeX(this).getUsers(limit: limit);

  Future<void> ensureLoaded({int? limit}) =>
      _RecommendedUserListControllerRuntimeX(this).ensureLoaded(limit: limit);
}
