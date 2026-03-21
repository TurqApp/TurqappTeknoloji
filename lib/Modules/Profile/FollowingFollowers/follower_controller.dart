import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Modules/Profile/FollowingFollowers/following_followers_controller.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class FollowerController extends GetxController {
  var avatarUrl = "".obs;
  var nickname = "".obs;
  var fullname = "".obs;
  var isLoaded = false.obs;
  var isFollowed = false.obs;
  var followLoading = false.obs;
  static const Duration _followStateCacheTtl = Duration(seconds: 20);
  static const Duration _followStateStaleRetention = Duration(minutes: 3);
  static const int _maxFollowStateCacheEntries = 800;
  static const Duration _userCacheTtl = Duration(minutes: 5);
  static const Duration _userCacheStaleRetention = Duration(minutes: 20);
  static const int _maxUserCacheEntries = 400;
  static final Map<String, _FollowerUserCacheEntry> _userCacheById =
      <String, _FollowerUserCacheEntry>{};
  static final Map<String, _FollowStateCacheEntry> _followStateCacheByUser =
      <String, _FollowStateCacheEntry>{};
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();

  Future<void> getData(String userID) async {
    if (isLoaded.value) return;
    _pruneUserCache();

    final cached = _userCacheById[userID];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _userCacheTtl) {
      avatarUrl.value = cached.avatarUrl;
      nickname.value = cached.nickname;
      fullname.value = cached.fullname;
      isLoaded.value = true;
      return;
    }

    final data = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (data != null) {
      final resolvedAvatar = data.avatarUrl;
      final resolvedNickname = data.nickname;
      final resolvedFullname = data.displayName;
      avatarUrl.value = resolvedAvatar;
      nickname.value = resolvedNickname;
      fullname.value = resolvedFullname;
      _userCacheById[userID] = _FollowerUserCacheEntry(
        avatarUrl: resolvedAvatar,
        nickname: resolvedNickname,
        fullname: resolvedFullname,
        cachedAt: DateTime.now(),
      );
    }

    isLoaded.value = true;
  }

  void _pruneUserCache() {
    final now = DateTime.now();
    _userCacheById.removeWhere(
      (_, entry) => now.difference(entry.cachedAt) > _userCacheStaleRetention,
    );
    if (_userCacheById.length <= _maxUserCacheEntries) return;
    final entries = _userCacheById.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = _userCacheById.length - _maxUserCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _userCacheById.remove(entries[i].key);
    }
  }

  Future<void> followControl(String userID) async {
    final myUid = CurrentUserService.instance.userId;
    if (myUid.isEmpty) return;
    _pruneFollowStateCache();

    final cacheKey = '$myUid:$userID';
    final cached = _followStateCacheByUser[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _followStateCacheTtl) {
      isFollowed.value = cached.isFollowed;
      return;
    }

    final exists = await _followRepository.isFollowing(
      userID,
      currentUid: myUid,
      preferCache: true,
    );
    isFollowed.value = exists;
    _followStateCacheByUser[cacheKey] = _FollowStateCacheEntry(
      isFollowed: exists,
      cachedAt: DateTime.now(),
    );
  }

  Future<void> follow(String otherUserID) async {
    if (followLoading.value) return;
    final wasFollowed = isFollowed.value;
    isFollowed.value = !wasFollowed; // optimistic
    followLoading.value = true;
    late final FollowToggleOutcome outcome;
    try {
      outcome = await FollowService.toggleFollow(otherUserID);
    } catch (_) {
      isFollowed.value = wasFollowed;
      isFollowed.refresh();
      AppSnackbar('common.error'.tr, 'following.update_failed'.tr);
      followLoading.value = false;
      return;
    }

    isFollowed.value = outcome.nowFollowing; // reconcile
    isFollowed.refresh();

    final myUid = CurrentUserService.instance.userId;
    if (myUid.isNotEmpty) {
      try {
        _followStateCacheByUser['$myUid:$otherUserID'] = _FollowStateCacheEntry(
          isFollowed: outcome.nowFollowing,
          cachedAt: DateTime.now(),
        );
        FollowingFollowersController.applyFollowMutationToCaches(
          currentUid: myUid,
          otherUserID: otherUserID,
          nowFollowing: outcome.nowFollowing,
        );
      } catch (_) {
        // Follow already succeeded; ignore local sync errors here.
      }
    }

    if (outcome.limitReached) {
      AppSnackbar('following.limit_title'.tr, 'following.limit_body'.tr);
    }

    followLoading.value = false;
  }

  void _pruneFollowStateCache() {
    final now = DateTime.now();
    _followStateCacheByUser.removeWhere(
      (_, entry) => now.difference(entry.cachedAt) > _followStateStaleRetention,
    );
    if (_followStateCacheByUser.length <= _maxFollowStateCacheEntries) return;
    final entries = _followStateCacheByUser.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount =
        _followStateCacheByUser.length - _maxFollowStateCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _followStateCacheByUser.remove(entries[i].key);
    }
  }
}

class _FollowerUserCacheEntry {
  final String avatarUrl;
  final String nickname;
  final String fullname;
  final DateTime cachedAt;

  const _FollowerUserCacheEntry({
    required this.avatarUrl,
    required this.nickname,
    required this.fullname,
    required this.cachedAt,
  });
}

class _FollowStateCacheEntry {
  final bool isFollowed;
  final DateTime cachedAt;

  const _FollowStateCacheEntry({
    required this.isFollowed,
    required this.cachedAt,
  });
}
