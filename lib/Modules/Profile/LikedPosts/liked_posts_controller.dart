import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Models/user_post_reference.dart';
import 'package:turqappv2/Services/user_post_link_service.dart';

class LikedPostControllers extends GetxController {
  final RxList<PostsModel> all = <PostsModel>[].obs;
  final selection = 0.obs;
  PageController pageController = PageController(initialPage: 0);
  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;

  final UserPostLinkService _linkService = Get.put(UserPostLinkService());
  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<UserPostReference>>? _likedSub;
  final Map<int, GlobalKey> _postKeys = {};

  String? _currentUserId;
  List<UserPostReference> _latestRefs = const [];
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bindAuth();
  }

  void _bindAuth() {
    _authSub = FirebaseAuth.instance.userChanges().listen((user) {
      _currentUserId = user?.uid;
      _likedSub?.cancel();
      all.clear();
      if (user != null) {
        _bindLiked(user.uid);
      }
    });
  }

  void _bindLiked(String userId) {
    _likedSub = _linkService.listenLikedPosts(userId).listen((refs) {
      _latestRefs = refs;
      _hydrate(userId, refs);
    });
  }

  Future<void> _hydrate(String userId, List<UserPostReference> refs) async {
    isLoading.value = true;
    all.clear();

    try {
      final posts = await _linkService.fetchLikedPosts(userId, refs);
      final visiblePosts = posts.where((p) => p.deletedPost != true).toList();
      all.assignAll(visiblePosts);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _hydrate(userId, _latestRefs);
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  GlobalKey getPostKey(int index) {
    return _postKeys.putIfAbsent(
        index, () => GlobalObjectKey('liked_post_$index'));
  }

  @override
  void onClose() {
    _likedSub?.cancel();
    _authSub?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
