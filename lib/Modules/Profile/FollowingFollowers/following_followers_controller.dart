import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FollowingFollowersController extends GetxController {
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

  var nickname = "".obs;

  FollowingFollowersController(
      {required this.userId, required int initialPage}) {
    selection.value = initialPage;
  }

  @override
  void onInit() {
    super.onInit();
    FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .get()
        .then((doc) {
      nickname.value = doc.get("nickname");
    });
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
    FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("followers")
        .count()
        .get()
        .then((aggregateQuerySnapshot) {
      takipciCounter.value = aggregateQuerySnapshot.count ?? 0;
      print("CEKILDI SETEDILDI");
    });

    FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("followings")
        .count()
        .get()
        .then((aggregateQuerySnapshot) {
      takipedilenCounter.value = aggregateQuerySnapshot.count ?? 0;
      print("CEKILDI SETEDILDI");
    });
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
    takipciler.value = results;
  }

  Future<void> searchTakipEdilenler() async {
    final q = searchTakipEdilenController.text.toLowerCase();
    if (q.length < 3) return;

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

  /// Sayfa değiştirme
  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}

class _RelationIdSetCacheEntry {
  final Set<String> ids;
  final DateTime cachedAt;

  const _RelationIdSetCacheEntry({
    required this.ids,
    required this.cachedAt,
  });
}
