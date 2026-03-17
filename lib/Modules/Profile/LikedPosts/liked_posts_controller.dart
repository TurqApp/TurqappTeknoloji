import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Models/user_post_reference.dart';
import 'package:turqappv2/Services/user_post_link_service.dart';

class LikedPostControllers extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

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
      unawaited(_bootstrap(userId, refs));
    });
  }

  Future<void> _bootstrap(String userId, List<UserPostReference> refs) async {
    if (refs.isEmpty) {
      all.clear();
      isLoading.value = false;
      return;
    }

    final cached = await _linkService.fetchLikedPosts(
      userId,
      refs,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      _applyPosts(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'liked_posts:$userId',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(_hydrate(
          userId,
          refs,
          silent: true,
          forceRefresh: true,
        ));
      }
      return;
    }

    await _hydrate(userId, refs);
  }

  Future<void> _hydrate(
    String userId,
    List<UserPostReference> refs, {
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent) {
      isLoading.value = true;
      all.clear();
    }

    try {
      final posts = await _linkService.fetchLikedPosts(
        userId,
        refs,
        preferCache: !forceRefresh,
      );
      _applyPosts(posts);
      SilentRefreshGate.markRefreshed('liked_posts:$userId');
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

  void _applyPosts(List<PostsModel> posts) {
    final visiblePosts = posts.where((p) => p.deletedPost != true).toList();
    all.assignAll(visiblePosts);
  }

  @override
  void onClose() {
    _likedSub?.cancel();
    _authSub?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
