import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

part 'following_followers_controller_cache_part.dart';
part 'following_followers_controller_models_part.dart';
part 'following_followers_controller_search_part.dart';
part 'following_followers_controller_mutation_part.dart';

class FollowingFollowersController extends GetxController {
  static const Duration _nicknameCacheTtl = Duration(minutes: 5);
  static const Duration _nicknameCacheStaleRetention = Duration(minutes: 20);
  static const int _maxNicknameCacheEntries = 300;
  static const Duration _searchResultCacheTtl = Duration(seconds: 30);
  static const Duration _searchResultStaleRetention = Duration(minutes: 3);
  static const int _maxSearchResultEntries = 400;
  static const Duration _counterCacheTtl = Duration(seconds: 30);
  static const Duration _counterCacheStaleRetention = Duration(minutes: 3);
  static const int _maxCounterCacheEntries = 300;
  static const Duration _relationListCacheTtl = Duration(minutes: 10);
  static const Duration _relationListCacheStaleRetention = Duration(hours: 1);
  static const int _maxRelationListCacheEntries = 400;
  static final Map<String, _NicknameCacheEntry> _nicknameCacheByUserId =
      <String, _NicknameCacheEntry>{};
  static final Map<String, _CounterCacheEntry> _counterCacheByUserId =
      <String, _CounterCacheEntry>{};
  static final Map<String, _RelationListCacheEntry>
      _followersListCacheByUserId = <String, _RelationListCacheEntry>{};
  static final Map<String, _RelationListCacheEntry>
      _followingsListCacheByUserId = <String, _RelationListCacheEntry>{};

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }

  var selection = 0.obs;
  final PageController pageController = PageController();
  RxList<String> takipciler = <String>[].obs;
  RxList<String> takipEdilenler = <String>[].obs;

  static const int _selfInitialLimit =
      ReadBudgetRegistry.followRelationPreviewInitialLimit;
  static const int _selfRefreshLimit =
      ReadBudgetRegistry.followRelationPreviewInitialLimit;
  static const int _otherUserLimit =
      ReadBudgetRegistry.followRelationPreviewInitialLimit;
  bool isLoadingFollowers = false;
  bool isLoadingFollowing = false;
  bool hasMoreFollowers = true;
  bool hasMoreFollowing = true;
  var takipciCounter = 0.obs;
  var takipedilenCounter = 0.obs;

  final TextEditingController searchTakipciController = TextEditingController();
  final TextEditingController searchTakipEdilenController =
      TextEditingController();
  final String userId;
  static const Duration _relationSearchCacheTtl = Duration(seconds: 30);
  final Map<String, _RelationIdSetCacheEntry> _relationIdSetCache =
      <String, _RelationIdSetCacheEntry>{};
  final Map<String, _SearchResultCacheEntry> _searchResultCache =
      <String, _SearchResultCacheEntry>{};
  Duration get searchResultCacheTtl => _searchResultCacheTtl;
  Duration get relationSearchCacheTtl => _relationSearchCacheTtl;
  Duration get searchResultStaleRetention => _searchResultStaleRetention;
  int get maxSearchResultEntries => _maxSearchResultEntries;

  var nickname = "".obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();
  final VisibilityPolicyService _visibilityPolicy =
      VisibilityPolicyService.ensure();

  static FollowingFollowersController ensure({
    required String userId,
    required int initialPage,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      FollowingFollowersController(
        userId: userId,
        initialPage: initialPage,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static FollowingFollowersController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<FollowingFollowersController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<FollowingFollowersController>(tag: tag);
  }

  FollowingFollowersController({
    required String userId,
    required int initialPage,
  }) : userId = userId.trim() {
    selection.value = initialPage;
  }

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  bool get isSelf => _resolveIsSelf();

  static void applyFollowMutationToCaches({
    required String currentUid,
    required String otherUserID,
    required bool nowFollowing,
  }) =>
      _applyFollowMutationToCachesImpl(
        currentUid: currentUid,
        otherUserID: otherUserID,
        nowFollowing: nowFollowing,
      );

  void _handleOnInit() {
    _loadNicknameCached();
    final followersCached = _restoreRelationListCache(isFollowers: true);
    final followingsCached = _restoreRelationListCache(isFollowers: false);
    unawaited(
      getFollowers(
        initial: true,
        forceServer: followersCached,
      ),
    );
    unawaited(
      getFollowing(
        initial: true,
        forceServer: followingsCached,
      ),
    );
    unawaited(
      _reconcileInitialRelations(
        followersCached: followersCached,
        followingsCached: followingsCached,
      ),
    );
  }

  Future<void> _reconcileInitialRelations({
    required bool followersCached,
    required bool followingsCached,
  }) async {
    await getCounters();
    final expectedFollowers = takipciCounter.value.clamp(
      0,
      ReadBudgetRegistry.followRelationPreviewInitialLimit,
    );
    if ((takipciCounter.value > 0 &&
            takipciler.isEmpty &&
            !isLoadingFollowers) ||
        (followersCached &&
            !isLoadingFollowers &&
            takipciler.length < expectedFollowers)) {
      await getFollowers(initial: true, forceServer: true);
    }
    final expectedFollowing = takipedilenCounter.value.clamp(
      0,
      ReadBudgetRegistry.followRelationPreviewInitialLimit,
    );
    if (takipedilenCounter.value > 0 &&
        takipEdilenler.isEmpty &&
        !isLoadingFollowing) {
      await getFollowing(initial: true, forceServer: true);
    }
    if (followingsCached &&
        !isLoadingFollowing &&
        takipEdilenler.length < expectedFollowing) {
      await getFollowing(initial: true, forceServer: true);
    }
  }

  void _handleOnClose() {
    pageController.dispose();
    searchTakipciController.dispose();
    searchTakipEdilenController.dispose();
  }

  bool _resolveIsSelf() => isCurrentUserId(userId);
}
