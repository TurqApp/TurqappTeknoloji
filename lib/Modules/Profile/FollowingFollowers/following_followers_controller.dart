import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:turqappv2/Core/Repositories/follow_repository.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';

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
    pageController.dispose();
    searchTakipciController.dispose();
    searchTakipEdilenController.dispose();
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
  final UserRepository _userRepository = UserRepository.ensure();
  final FollowRepository _followRepository = FollowRepository.ensure();

  FollowingFollowersController(
      {required this.userId, required int initialPage}) {
    selection.value = initialPage;
  }

  @override
  void onInit() {
    super.onInit();
    _loadNicknameCached();
    getCounters();
    final followersCached = _restoreRelationListCache(isFollowers: true);
    final followingsCached = _restoreRelationListCache(isFollowers: false);
    if (!followersCached) {
      getFollowers(initial: true);
    }
    if (!followingsCached) {
      getFollowing(initial: true);
    }
  }

  bool get isSelf => FirebaseAuth.instance.currentUser?.uid == userId;

  int _resolveLimit({required bool initial}) {
    if (isSelf) {
      return initial ? _selfInitialLimit : _selfRefreshLimit;
    }
    return _otherUserLimit;
  }

  Future<void> getCounters() async {
    _pruneCounterCache();
    final cached = _counterCacheByUserId[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _counterCacheTtl) {
      takipciCounter.value = cached.followers;
      takipedilenCounter.value = cached.followings;
      return;
    }

    try {
      final data = await _userRepository.getUserRaw(userId);
      final followers =
          ((data?['followerCount'] ?? data?['followersCount']) as num?)
                  ?.toInt() ??
              0;
      final followings =
          ((data?['followingCount'] ?? data?['followingsCount']) as num?)
                  ?.toInt() ??
              0;
      takipciCounter.value = followers;
      takipedilenCounter.value = followings;
      _counterCacheByUserId[userId] = _CounterCacheEntry(
        followers: followers,
        followings: followings,
        cachedAt: DateTime.now(),
      );
    } catch (_) {}
  }

  Future<void> _loadNicknameCached() async {
    _pruneNicknameCache();
    final cached = _nicknameCacheByUserId[userId];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _nicknameCacheTtl) {
      nickname.value = cached.nickname;
      return;
    }
    try {
      final data = await _userRepository.getUserRaw(userId);
      final name = ((data?['nickname'] ?? data?['username'] ?? '')
              .toString()
              .trim());
      nickname.value = name;
      _nicknameCacheByUserId[userId] = _NicknameCacheEntry(
        nickname: name,
        cachedAt: DateTime.now(),
      );
    } catch (_) {}
  }

  void _pruneNicknameCache() {
    final now = DateTime.now();
    _nicknameCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) > _nicknameCacheStaleRetention,
    );
    if (_nicknameCacheByUserId.length <= _maxNicknameCacheEntries) return;
    final entries = _nicknameCacheByUserId.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount =
        _nicknameCacheByUserId.length - _maxNicknameCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _nicknameCacheByUserId.remove(entries[i].key);
    }
  }

  Future<void> getFollowers(
      {bool initial = false, bool forceServer = false}) async {
    if (isLoadingFollowers) return;
    if (!isSelf && takipciler.isNotEmpty) return; // başkasında tek sefer getir

    if (initial &&
        !forceServer &&
        _restoreRelationListCache(isFollowers: true)) {
      return;
    }

    isLoadingFollowers = true;
    if (initial) {
      takipciler.clear();
      hasMoreFollowers = true;
    }

    final fetchLimit = _resolveLimit(initial: initial);
    final ids = await _followRepository.getFollowerIds(
      userId,
      preferCache: !forceServer,
      forceRefresh: forceServer,
    );
    takipciler.value = ids.take(fetchLimit).toList(growable: false);
    hasMoreFollowers = false;

    _saveRelationListCache(isFollowers: true);
    isLoadingFollowers = false;
  }

  Future<void> getFollowing(
      {bool initial = false, bool forceServer = false}) async {
    if (isLoadingFollowing) return;
    if (!isSelf && takipEdilenler.isNotEmpty)
      return; // başkasında tek sefer getir

    if (initial &&
        !forceServer &&
        _restoreRelationListCache(isFollowers: false)) {
      return;
    }

    isLoadingFollowing = true;
    if (initial) {
      takipEdilenler.clear();
      hasMoreFollowing = true;
    }

    final fetchLimit = _resolveLimit(initial: initial);
    final ids = await _followRepository.getFollowingIds(
      userId,
      preferCache: !forceServer,
      forceRefresh: forceServer,
    );
    takipEdilenler.value = ids.take(fetchLimit).toList(growable: false);
    hasMoreFollowing = false;

    _saveRelationListCache(isFollowers: false);
    isLoadingFollowing = false;
  }

  bool _restoreRelationListCache({required bool isFollowers}) {
    _pruneRelationListCache();
    final entry = isFollowers
        ? _followersListCacheByUserId[userId]
        : _followingsListCacheByUserId[userId];
    if (entry == null) return false;
    if (DateTime.now().difference(entry.cachedAt) > _relationListCacheTtl) {
      return false;
    }
    if (isFollowers) {
      takipciler.value = List<String>.from(entry.ids);
      hasMoreFollowers = false;
    } else {
      takipEdilenler.value = List<String>.from(entry.ids);
      hasMoreFollowing = false;
    }
    return true;
  }

  void _saveRelationListCache({required bool isFollowers}) {
    final now = DateTime.now();
    if (isFollowers) {
      _followersListCacheByUserId[userId] = _RelationListCacheEntry(
        ids: List<String>.from(takipciler),
        cachedAt: now,
      );
    } else {
      _followingsListCacheByUserId[userId] = _RelationListCacheEntry(
        ids: List<String>.from(takipEdilenler),
        cachedAt: now,
      );
    }
  }

  void _pruneRelationListCache() {
    final now = DateTime.now();
    _followersListCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) > _relationListCacheStaleRetention,
    );
    _followingsListCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) > _relationListCacheStaleRetention,
    );

    void trimCache(Map<String, _RelationListCacheEntry> target) {
      if (target.length <= _maxRelationListCacheEntries) return;
      final entries = target.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
      final removeCount = target.length - _maxRelationListCacheEntries;
      for (var i = 0; i < removeCount; i++) {
        target.remove(entries[i].key);
      }
    }

    trimCache(_followersListCacheByUserId);
    trimCache(_followingsListCacheByUserId);
  }

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

    if (Get.isRegistered<FollowingFollowersController>(tag: currentUid)) {
      final c = Get.find<FollowingFollowersController>(tag: currentUid);
      c._applyLocalMutation(
        currentUid: currentUid,
        otherUserID: otherUserID,
        nowFollowing: nowFollowing,
      );
    }
    if (Get.isRegistered<FollowingFollowersController>(tag: otherUserID)) {
      final c = Get.find<FollowingFollowersController>(tag: otherUserID);
      c._applyLocalMutation(
        currentUid: currentUid,
        otherUserID: otherUserID,
        nowFollowing: nowFollowing,
      );
    }
  }

  void _applyLocalMutation({
    required String currentUid,
    required String otherUserID,
    required bool nowFollowing,
  }) {
    if (userId == currentUid) {
      if (nowFollowing) {
        if (!takipEdilenler.contains(otherUserID)) {
          takipEdilenler.insert(0, otherUserID);
        }
      } else {
        takipEdilenler.remove(otherUserID);
      }
      takipedilenCounter.value = nowFollowing
          ? takipedilenCounter.value + 1
          : (takipedilenCounter.value - 1).clamp(0, 1 << 30);
      _saveRelationListCache(isFollowers: false);
      _relationIdSetCache['followings'] = _RelationIdSetCacheEntry(
        ids: takipEdilenler.toSet(),
        cachedAt: DateTime.now(),
      );
    }
    if (userId == otherUserID) {
      if (nowFollowing) {
        if (!takipciler.contains(currentUid)) {
          takipciler.insert(0, currentUid);
        }
      } else {
        takipciler.remove(currentUid);
      }
      takipciCounter.value = nowFollowing
          ? takipciCounter.value + 1
          : (takipciCounter.value - 1).clamp(0, 1 << 30);
      _saveRelationListCache(isFollowers: true);
      _relationIdSetCache['followers'] = _RelationIdSetCacheEntry(
        ids: takipciler.toSet(),
        cachedAt: DateTime.now(),
      );
    }
  }

  Future<void> searchTakipci() async {
    final q = searchTakipciController.text.toLowerCase();
    if (q.length < 3) return;
    _pruneSearchResultCache();

    final cached = _searchResultCache['followers:$q'];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _searchResultCacheTtl) {
      takipciler.value = cached.ids;
      return;
    }

    final followerIDs = await _getRelationIdsCached('followers');
    final results = await _filterRelationIdsByQuery(followerIDs, q);
    _searchResultCache['followers:$q'] = _SearchResultCacheEntry(
      ids: List<String>.from(results),
      cachedAt: DateTime.now(),
    );
    takipciler.value = results;
  }

  Future<void> searchTakipEdilenler() async {
    final q = searchTakipEdilenController.text.toLowerCase();
    if (q.length < 3) return;
    _pruneSearchResultCache();

    final cached = _searchResultCache['followings:$q'];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _searchResultCacheTtl) {
      takipEdilenler.value = cached.ids;
      return;
    }

    final followingIDs = await _getRelationIdsCached('followings');
    final results = await _filterRelationIdsByQuery(followingIDs, q);
    _searchResultCache['followings:$q'] = _SearchResultCacheEntry(
      ids: List<String>.from(results),
      cachedAt: DateTime.now(),
    );
    takipEdilenler.value = results;
  }

  Future<Set<String>> _getRelationIdsCached(String relation) async {
    final now = DateTime.now();
    final cached = _relationIdSetCache[relation];
    if (cached != null &&
        now.difference(cached.cachedAt) <= _relationSearchCacheTtl) {
      return cached.ids;
    }

    final ids = relation == 'followers'
        ? await _followRepository.getFollowerIds(
            userId,
            preferCache: true,
            forceRefresh: false,
          )
        : await _followRepository.getFollowingIds(
            userId,
            preferCache: true,
            forceRefresh: false,
          );
    _relationIdSetCache[relation] = _RelationIdSetCacheEntry(
      ids: ids,
      cachedAt: now,
    );
    return ids;
  }

  Future<List<String>> _filterRelationIdsByQuery(
      Set<String> relationIds, String q) async {
    if (relationIds.isEmpty) return const <String>[];
    final normalizedQuery = q.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return relationIds.toList(growable: false);
    final rawUsers = await _userRepository.getUsersRaw(
      relationIds.toList(growable: false),
    );
    final results = <String>[];
    for (final id in relationIds) {
      final data = rawUsers[id] ?? const <String, dynamic>{};
      final nickname =
          (data['nickname'] ?? data['username'] ?? '').toString().toLowerCase();
      final firstName = (data['firstName'] ?? '').toString().toLowerCase();
      final lastName = (data['lastName'] ?? '').toString().toLowerCase();
      final fullName = '$firstName $lastName'.trim();
      if (nickname.contains(normalizedQuery) ||
          fullName.contains(normalizedQuery)) {
        results.add(id);
      }
    }
    return results;
  }

  void _pruneSearchResultCache() {
    final now = DateTime.now();
    _searchResultCache.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) > _searchResultStaleRetention,
    );
    if (_searchResultCache.length <= _maxSearchResultEntries) return;
    final entries = _searchResultCache.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = _searchResultCache.length - _maxSearchResultEntries;
    for (var i = 0; i < removeCount; i++) {
      _searchResultCache.remove(entries[i].key);
    }
  }

  void _pruneCounterCache() {
    final now = DateTime.now();
    _counterCacheByUserId.removeWhere(
      (_, entry) =>
          now.difference(entry.cachedAt) > _counterCacheStaleRetention,
    );
    if (_counterCacheByUserId.length <= _maxCounterCacheEntries) return;
    final entries = _counterCacheByUserId.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = _counterCacheByUserId.length - _maxCounterCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _counterCacheByUserId.remove(entries[i].key);
    }
  }

  /// Sayfa değiştirme
  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
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
