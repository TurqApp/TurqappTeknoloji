import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';

class SocialProfileFollowersController extends GetxController {
  String userID;
  var selection = 0.obs;
  late PageController pageController;

  RxList<String> takipciler = <String>[].obs;
  RxList<String> takipEdilenler = <String>[].obs;

  final int limit = 50;
  bool isLoadingFollowers = false;
  bool isLoadingFollowing = false;
  bool hasMoreFollowers = true;
  bool hasMoreFollowing = true;
  static const Duration _relationCacheTtl = Duration(seconds: 30);
  static const Duration _relationCacheStaleRetention = Duration(minutes: 3);
  static const int _maxRelationCacheEntries = 400;
  static final Map<String, _RelationListCacheEntry> _relationCache =
      <String, _RelationListCacheEntry>{};
  final FollowRepository _followRepository = FollowRepository.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();

  static SocialProfileFollowersController ensure({
    required int initialPage,
    required String userID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SocialProfileFollowersController(
        initialPage: initialPage,
        userID: userID,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static SocialProfileFollowersController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<SocialProfileFollowersController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SocialProfileFollowersController>(tag: tag);
  }

  SocialProfileFollowersController(
      {required int initialPage, required this.userID}) {
    selection.value = initialPage;
    pageController = PageController(initialPage: initialPage);
  }

  @override
  void onInit() {
    super.onInit();
    getFollowers();
    getFollowing();
  }

  Future<void> getFollowers() async {
    _pruneRelationCache();
    final followersCacheKey = 'followers:$userID';
    final cachedFollowers = _relationCache[followersCacheKey];
    if (cachedFollowers != null &&
        DateTime.now().difference(cachedFollowers.cachedAt) <=
            _relationCacheTtl) {
      takipciler.value = List<String>.from(cachedFollowers.ids);
      hasMoreFollowers = false;
      return;
    }
    if (takipciler.isNotEmpty) return; // tek sefer gösterim
    if (isLoadingFollowers || !hasMoreFollowers) return;
    isLoadingFollowers = true;

    final ids = await _followRepository.getFollowerIds(
      userID,
      preferCache: true,
      forceRefresh: false,
    );
    takipciler.value = ids.take(limit).toList();
    _relationCache[followersCacheKey] = _RelationListCacheEntry(
      ids: List<String>.from(takipciler),
      cachedAt: DateTime.now(),
    );

    hasMoreFollowers = false; // başkasında yenileme/sayfalama yok
    isLoadingFollowers = false;
  }

  Future<void> getFollowing() async {
    _pruneRelationCache();
    final followingsCacheKey = 'followings:$userID';
    final cachedFollowings = _relationCache[followingsCacheKey];
    if (cachedFollowings != null &&
        DateTime.now().difference(cachedFollowings.cachedAt) <=
            _relationCacheTtl) {
      takipEdilenler.value = List<String>.from(cachedFollowings.ids);
      hasMoreFollowing = false;
      return;
    }
    if (takipEdilenler.isNotEmpty) return; // tek sefer gösterim
    if (isLoadingFollowing || !hasMoreFollowing) return;
    isLoadingFollowing = true;

    final ids = await _visibilityPolicy.loadViewerFollowingIds(
      viewerUserId: userID,
      preferCache: true,
      forceRefresh: false,
    );
    takipEdilenler.value = ids.take(limit).toList();
    _relationCache[followingsCacheKey] = _RelationListCacheEntry(
      ids: List<String>.from(takipEdilenler),
      cachedAt: DateTime.now(),
    );

    hasMoreFollowing = false; // başkasında yenileme/sayfalama yok
    isLoadingFollowing = false;
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _pruneRelationCache() {
    final now = DateTime.now();
    _relationCache.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) > _relationCacheStaleRetention,
    );
    if (_relationCache.length <= _maxRelationCacheEntries) return;
    final entries = _relationCache.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = _relationCache.length - _maxRelationCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _relationCache.remove(entries[i].key);
    }
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}

class _RelationListCacheEntry {
  final List<String> ids;
  final DateTime cachedAt;

  const _RelationListCacheEntry({
    required this.ids,
    required this.cachedAt,
  });
}
