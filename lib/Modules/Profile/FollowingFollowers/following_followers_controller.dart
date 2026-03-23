import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Services/visibility_policy_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Utils/current_user_utils.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';

part 'following_followers_controller_cache_part.dart';
part 'following_followers_controller_lifecycle_part.dart';
part 'following_followers_controller_search_part.dart';

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

  static const int _selfInitialLimit = 40;
  static const int _selfRefreshLimit = 30;
  static const int _otherUserLimit = 50;
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

  FollowingFollowersController(
      {required this.userId, required int initialPage}) {
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
  }) {
    final now = DateTime.now();
    final myFollowingEntry = _followingsListCacheByUserId[currentUid];
    if (myFollowingEntry != null) {
      final list = List<String>.from(myFollowingEntry.ids);
      if (nowFollowing) {
        if (!list.contains(otherUserID)) list.insert(0, otherUserID);
      } else {
        list.remove(otherUserID);
      }
      _followingsListCacheByUserId[currentUid] =
          _RelationListCacheEntry(ids: list, cachedAt: now);
    }

    final otherFollowersEntry = _followersListCacheByUserId[otherUserID];
    if (otherFollowersEntry != null) {
      final list = List<String>.from(otherFollowersEntry.ids);
      if (nowFollowing) {
        if (!list.contains(currentUid)) list.insert(0, currentUid);
      } else {
        list.remove(currentUid);
      }
      _followersListCacheByUserId[otherUserID] =
          _RelationListCacheEntry(ids: list, cachedAt: now);
    }

    final myCounter = _counterCacheByUserId[currentUid];
    if (myCounter != null) {
      final nextFollowings = nowFollowing
          ? myCounter.followings + 1
          : (myCounter.followings - 1).clamp(0, 1 << 30);
      _counterCacheByUserId[currentUid] = _CounterCacheEntry(
        followers: myCounter.followers,
        followings: nextFollowings,
        cachedAt: now,
      );
    }

    final otherCounter = _counterCacheByUserId[otherUserID];
    if (otherCounter != null) {
      final nextFollowers = nowFollowing
          ? otherCounter.followers + 1
          : (otherCounter.followers - 1).clamp(0, 1 << 30);
      _counterCacheByUserId[otherUserID] = _CounterCacheEntry(
        followers: nextFollowers,
        followings: otherCounter.followings,
        cachedAt: now,
      );
    }

    final currentController = maybeFind(tag: currentUid);
    if (currentController != null) {
      final c = currentController;
      c._applyLocalMutation(
        currentUid: currentUid,
        otherUserID: otherUserID,
        nowFollowing: nowFollowing,
      );
    }
    final otherController = maybeFind(tag: otherUserID);
    if (otherController != null) {
      final c = otherController;
      c._applyLocalMutation(
        currentUid: currentUid,
        otherUserID: otherUserID,
        nowFollowing: nowFollowing,
      );
    }
  }
}

class _NicknameCacheEntry {
  final String nickname;
  final DateTime cachedAt;

  const _NicknameCacheEntry({
    required this.nickname,
    required this.cachedAt,
  });
}

class _RelationIdSetCacheEntry {
  final Set<String> ids;
  final DateTime cachedAt;

  const _RelationIdSetCacheEntry({
    required this.ids,
    required this.cachedAt,
  });
}

class _SearchResultCacheEntry {
  final List<String> ids;
  final DateTime cachedAt;

  const _SearchResultCacheEntry({
    required this.ids,
    required this.cachedAt,
  });
}

class _CounterCacheEntry {
  final int followers;
  final int followings;
  final DateTime cachedAt;

  const _CounterCacheEntry({
    required this.followers,
    required this.followings,
    required this.cachedAt,
  });
}

class _RelationListCacheEntry {
  final List<String> ids;
  final DateTime cachedAt;

  const _RelationListCacheEntry({
    required this.ids,
    required this.cachedAt,
  });
}

class _RelationSearchPlan {
  const _RelationSearchPlan({
    required this.query,
    required this.cacheKey,
    required this.relation,
    required this.assignResult,
  });

  final String query;
  final String cacheKey;
  final String relation;
  final void Function(List<String> ids) assignResult;
}
