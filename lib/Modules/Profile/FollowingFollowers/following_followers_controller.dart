import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  static final Map<String, _NicknameCacheEntry> _nicknameCacheByUserId =
      <String, _NicknameCacheEntry>{};
  static final Map<String, _CounterCacheEntry> _counterCacheByUserId =
      <String, _CounterCacheEntry>{};

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
  DocumentSnapshot? lastFollowerDoc;
  DocumentSnapshot? lastFollowingDoc;
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

  FollowingFollowersController(
      {required this.userId, required int initialPage}) {
    selection.value = initialPage;
  }

  @override
  void onInit() {
    super.onInit();
    _loadNicknameCached();
    getCounters();
    getFollowers(initial: true);
    getFollowing(initial: true);
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
      final refs = FirebaseFirestore.instance.collection("users").doc(userId);
      final results = await Future.wait([
        refs.collection("followers").count().get(),
        refs.collection("followings").count().get(),
      ]);
      final followers = results[0].count ?? 0;
      final followings = results[1].count ?? 0;
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
      final doc =
          await FirebaseFirestore.instance.collection("users").doc(userId).get();
      final name = (doc.data()?['nickname'] ?? '').toString().trim();
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
      (_, entry) => now.difference(entry.cachedAt) > _nicknameCacheStaleRetention,
    );
    if (_nicknameCacheByUserId.length <= _maxNicknameCacheEntries) return;
    final entries = _nicknameCacheByUserId.entries.toList()
      ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));
    final removeCount = _nicknameCacheByUserId.length - _maxNicknameCacheEntries;
    for (var i = 0; i < removeCount; i++) {
      _nicknameCacheByUserId.remove(entries[i].key);
    }
  }

  Future<void> getFollowers({bool initial = false}) async {
    if (isLoadingFollowers) return;
    if (!isSelf && takipciler.isNotEmpty) return; // başkasında tek sefer getir

    isLoadingFollowers = true;
    if (initial) {
      takipciler.clear();
      lastFollowerDoc = null;
      hasMoreFollowers = true;
    }

    final fetchLimit = _resolveLimit(initial: initial);

    Query query = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("followers")
        .orderBy("timeStamp", descending: true)
        .limit(fetchLimit);

    if (isSelf && lastFollowerDoc != null) {
      query = query.startAfterDocument(lastFollowerDoc!);
    }

    final snap = await query.get();
    if (snap.docs.isNotEmpty) {
      lastFollowerDoc = snap.docs.last;
      for (var doc in snap.docs) {
        final id = doc.id;
        if (!takipciler.contains(id)) takipciler.add(id);
      }
    }

    if (!isSelf || snap.docs.length < fetchLimit) {
      // başkasında her zaman kapat; kendinde bittiğinde kapat
      hasMoreFollowers = false;
    }

    isLoadingFollowers = false;
  }

  Future<void> getFollowing({bool initial = false}) async {
    if (isLoadingFollowing) return;
    if (!isSelf && takipEdilenler.isNotEmpty)
      return; // başkasında tek sefer getir

    isLoadingFollowing = true;
    if (initial) {
      takipEdilenler.clear();
      lastFollowingDoc = null;
      hasMoreFollowing = true;
    }

    final fetchLimit = _resolveLimit(initial: initial);

    Query query = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("followings")
        .orderBy("timeStamp", descending: true)
        .limit(fetchLimit);

    if (isSelf && lastFollowingDoc != null) {
      query = query.startAfterDocument(lastFollowingDoc!);
    }

    final snap = await query.get();
    if (snap.docs.isNotEmpty) {
      lastFollowingDoc = snap.docs.last;
      for (var doc in snap.docs) {
        final id = doc.id;
        if (!takipEdilenler.contains(id)) takipEdilenler.add(id);
      }
    }

    if (!isSelf || snap.docs.length < fetchLimit) {
      hasMoreFollowing = false;
    }

    isLoadingFollowing = false;
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

    final next = q.substring(0, q.length - 1) +
        String.fromCharCode(q.codeUnitAt(q.length - 1) + 1);

    final followerIDs = await _getRelationIdsCached('followers');

    // 2. Nickname'e göre filtrele
    final querySnap = await FirebaseFirestore.instance
        .collection("users")
        .where('nickname', isGreaterThanOrEqualTo: q)
        .where('nickname', isLessThan: next)
        .get();

    final results = <String>[];
    for (var doc in querySnap.docs) {
      if (followerIDs.contains(doc.id)) {
        results.add(doc.id);
      }
    }
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

    final next = q.substring(0, q.length - 1) +
        String.fromCharCode(q.codeUnitAt(q.length - 1) + 1);

    final followingIDs = await _getRelationIdsCached('followings');

    // 2. Nickname'e göre filtrele
    final querySnap = await FirebaseFirestore.instance
        .collection("users")
        .where('nickname', isGreaterThanOrEqualTo: q)
        .where('nickname', isLessThan: next)
        .get();

    final results = <String>[];
    for (var doc in querySnap.docs) {
      if (followingIDs.contains(doc.id)) {
        results.add(doc.id);
      }
    }
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

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection(relation)
        .get();
    final ids = snap.docs.map((doc) => doc.id).toSet();
    _relationIdSetCache[relation] = _RelationIdSetCacheEntry(
      ids: ids,
      cachedAt: now,
    );
    return ids;
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
