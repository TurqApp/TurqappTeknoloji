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

  final int limit = 50; // başlangıç ve her fetch 30 kişi
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

  Future<void> getCounters() async {
    FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Takipciler")
        .count()
        .get()
        .then((aggregateQuerySnapshot) {
      takipciCounter.value = aggregateQuerySnapshot.count ?? 0;
      print("CEKILDI SETEDILDI");
    });

    FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("TakipEdilenler")
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

    Query query = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Takipciler")
        .orderBy("timeStamp", descending: true)
        .limit(limit);

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

    if (!isSelf || snap.docs.length < limit) {
      // başkasında her zaman kapat; kendinde bittiğinde kapat
      hasMoreFollowers = false;
    }

    isLoadingFollowers = false;
  }

  Future<void> getFollowing({bool initial = false}) async {
    if (isLoadingFollowing) return;
    if (!isSelf && takipEdilenler.isNotEmpty) return; // başkasında tek sefer getir

    isLoadingFollowing = true;
    if (initial) {
      takipEdilenler.clear();
      lastFollowingDoc = null;
      hasMoreFollowing = true;
    }

    Query query = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("TakipEdilenler")
        .orderBy("timeStamp", descending: true)
        .limit(limit);

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

    if (!isSelf || snap.docs.length < limit) {
      hasMoreFollowing = false;
    }

    isLoadingFollowing = false;
  }

  Future<void> searchTakipci() async {
    final q = searchTakipciController.text.toLowerCase();
    if (q.length < 3) return;

    final next = q.substring(0, q.length - 1) +
        String.fromCharCode(q.codeUnitAt(q.length - 1) + 1);

    // 1. Bu kullanıcının tüm takipçi ID'lerini çek
    final allFollowersSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("Takipciler")
        .get();
    final followerIDs = allFollowersSnap.docs.map((doc) => doc.id).toSet();

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

    // 1. Tüm takip edilen ID'leri çek
    final allFollowingSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("TakipEdilenler")
        .get();
    final followingIDs = allFollowingSnap.docs.map((doc) => doc.id).toSet();

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

  /// Sayfa değiştirme
  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
