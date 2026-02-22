import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SocialProfileFollowersController extends GetxController {
  String userID;
  var selection = 0.obs;
  late PageController pageController;

  RxList<String> takipciler = <String>[].obs;
  RxList<String> takipEdilenler = <String>[].obs;

  final int limit = 20;
  DocumentSnapshot? lastFollowerDoc;
  DocumentSnapshot? lastFollowingDoc;
  bool isLoadingFollowers = false;
  bool isLoadingFollowing = false;
  bool hasMoreFollowers = true;
  bool hasMoreFollowing = true;

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
    if (isLoadingFollowers || !hasMoreFollowers) return;
    isLoadingFollowers = true;

    Query query = FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .collection("Takipciler")
        .orderBy("timeStamp", descending: true)
        .limit(limit);

    if (lastFollowerDoc != null) {
      query = query.startAfterDocument(lastFollowerDoc!);
    }

    final snap = await query.get();
    if (snap.docs.isNotEmpty) {
      lastFollowerDoc = snap.docs.last;
      takipciler.addAll(snap.docs.map((val) => val.id));
    }

    if (snap.docs.length < limit) hasMoreFollowers = false;
    isLoadingFollowers = false;
  }

  Future<void> getFollowing() async {
    if (isLoadingFollowing || !hasMoreFollowing) return;
    isLoadingFollowing = true;

    Query query = FirebaseFirestore.instance
        .collection("users")
        .doc(userID)
        .collection("TakipEdilenler")
        .orderBy("timeStamp", descending: true)
        .limit(limit);

    if (lastFollowingDoc != null) {
      query = query.startAfterDocument(lastFollowingDoc!);
    }

    final snap = await query.get();
    if (snap.docs.isNotEmpty) {
      lastFollowingDoc = snap.docs.last;
      takipEdilenler.addAll(snap.docs.map((val) => val.id));
    }

    if (snap.docs.length < limit) hasMoreFollowing = false;
    isLoadingFollowing = false;
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
}
