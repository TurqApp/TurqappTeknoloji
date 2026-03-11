import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LikeUserItem {
  const LikeUserItem({
    required this.userID,
    required this.nickname,
    required this.fullName,
    required this.avatarUrl,
  });

  final String userID;
  final String nickname;
  final String fullName;
  final String avatarUrl;
}

class PostLikeListingController extends GetxController {
  PostLikeListingController({required this.postID});

  final String postID;
  final RxList<LikeUserItem> users = <LikeUserItem>[].obs;
  final RxString query = ''.obs;
  final TextEditingController searchController = TextEditingController();

  List<LikeUserItem> get filteredUsers {
    final term = query.value.trim().toLowerCase();
    if (term.isEmpty) return users;
    return users.where((user) {
      return user.nickname.toLowerCase().contains(term) ||
          user.fullName.toLowerCase().contains(term);
    }).toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    getLikes();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    query.value = value;
  }

  Future<void> getLikes() async {
    final snap = await FirebaseFirestore.instance
        .collection("Posts")
        .doc(postID)
        .collection("likes")
        .orderBy("timeStamp", descending: true)
        .get();

    final ids = snap.docs.map((v) => v.id).toList();
    final fetched = await Future.wait(ids.map(_fetchUserItem));
    users.value = fetched.whereType<LikeUserItem>().toList(growable: false);
  }

  Future<LikeUserItem?> _fetchUserItem(String userID) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(userID).get();
      final data = doc.data() ?? const <String, dynamic>{};
      final nickname =
          (data['nickname'] ?? data['username'] ?? data['displayName'] ?? '')
              .toString()
              .trim();
      final fullName =
          '${(data['firstName'] ?? '').toString()} ${(data['lastName'] ?? '').toString()}'
              .trim();
      final avatarUrl = (data['avatarUrl'] ?? '').toString().trim();

      return LikeUserItem(
        userID: userID,
        nickname: nickname,
        fullName: fullName,
        avatarUrl: avatarUrl,
      );
    } catch (_) {
      return null;
    }
  }
}
