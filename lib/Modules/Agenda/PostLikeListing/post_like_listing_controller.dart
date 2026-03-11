import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LikeUserItem {
  const LikeUserItem({
    required this.userID,
    required this.nickname,
    required this.fullName,
    required this.avatarUrl,
    required this.searchText,
  });

  final String userID;
  final String nickname;
  final String fullName;
  final String avatarUrl;
  final String searchText;
}

class PostLikeListingController extends GetxController {
  PostLikeListingController({required this.postID});

  final String postID;
  final RxList<LikeUserItem> users = <LikeUserItem>[].obs;
  final RxList<LikeUserItem> filteredUsers = <LikeUserItem>[].obs;
  final RxString query = ''.obs;
  final TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_syncQueryFromInput);
    ever<List<LikeUserItem>>(users, (_) => _applyFilter());
    ever<String>(query, (_) => _applyFilter());
    getLikes();
  }

  @override
  void onClose() {
    searchController.removeListener(_syncQueryFromInput);
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    final normalized = _normalize(value);
    if (query.value == normalized) return;
    query.value = normalized;
    debugPrint('[PostLikeSearch] query="$normalized"');
  }

  void _syncQueryFromInput() {
    onSearchChanged(searchController.text);
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
    _applyFilter();
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
      final username =
          (data['username'] ?? data['usernameLower'] ?? data['displayName'] ?? '')
              .toString()
              .trim();
      final fullName =
          '${(data['firstName'] ?? '').toString()} ${(data['lastName'] ?? '').toString()}'
              .trim();
      final avatarUrl = (data['avatarUrl'] ?? '').toString().trim();
      final searchText = _normalize([
        nickname,
        username,
        fullName,
        userID,
      ].join(' '));

      return LikeUserItem(
        userID: userID,
        nickname: nickname,
        fullName: fullName,
        avatarUrl: avatarUrl,
        searchText: searchText,
      );
    } catch (_) {
      return null;
    }
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .trim();
  }

  void _applyFilter() {
    final term = _normalize(query.value);
    if (term.isEmpty) {
      filteredUsers.assignAll(users);
    } else {
      filteredUsers.assignAll(
        users.where((user) => user.searchText.contains(term)),
      );
    }
    debugPrint(
      '[PostLikeSearch] total=${users.length} filtered=${filteredUsers.length} term="$term"',
    );
  }
}
