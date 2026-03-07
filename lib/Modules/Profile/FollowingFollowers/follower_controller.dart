import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/follow_service.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Utils/avatar_url.dart';

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

  String _resolveAvatar(Map<String, dynamic> data) {
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    return resolveAvatarUrl(data, profile: profile).trim();
  }

  String _resolveNickname(Map<String, dynamic> data) {
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    return (data['nickname'] ??
            profile['nickname'] ??
            data['username'] ??
            profile['username'] ??
            data['usernameLower'] ??
            profile['usernameLower'] ??
            '')
        .toString()
        .trim();
  }

  String _resolveFullName(Map<String, dynamic> data) {
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    final firstName =
        (data['firstName'] ?? profile['firstName'] ?? '').toString().trim();
    final lastName =
        (data['lastName'] ?? profile['lastName'] ?? '').toString().trim();
    return '$firstName $lastName'.trim();
  }

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

    final userDoc =
        await FirebaseFirestore.instance.collection("users").doc(userID).get();
    final data = Map<String, dynamic>.from(userDoc.data() ?? const {});
    if (data.isNotEmpty) {
      final resolvedAvatar = _resolveAvatar(data);
      final resolvedNickname = _resolveNickname(data);
      final resolvedFullname = _resolveFullName(data);
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
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) return;
    _pruneFollowStateCache();

    final cacheKey = '$myUid:$userID';
    final cached = _followStateCacheByUser[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _followStateCacheTtl) {
      isFollowed.value = cached.isFollowed;
      return;
    }

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(myUid)
        .collection("followings")
        .doc(userID)
        .get();
    final exists = doc.exists;
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
    final outcome = await FollowService.toggleFollow(otherUserID);
    isFollowed.value = outcome.nowFollowing; // reconcile
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid != null) {
      _followStateCacheByUser['$myUid:$otherUserID'] = _FollowStateCacheEntry(
        isFollowed: outcome.nowFollowing,
        cachedAt: DateTime.now(),
      );
    }
    if (outcome.limitReached) {
      AppSnackbar('Takip Limiti', 'Günlük daha fazla kişi takip edilemiyor.');
    }
    followLoading.value = false;
  }

  void _pruneFollowStateCache() {
    final now = DateTime.now();
    _followStateCacheByUser.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) > _followStateStaleRetention,
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
