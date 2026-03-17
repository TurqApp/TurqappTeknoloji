import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Models/user_post_reference.dart';
import 'package:turqappv2/Services/user_post_link_service.dart';

class SavedPostsController extends GetxController {
  final RxList<PostsModel> savedPhotos = <PostsModel>[].obs;
  final RxList<PostsModel> savedVideos = <PostsModel>[].obs;
  final RxList<PostsModel> savedAgendas = <PostsModel>[].obs;

  final selection = 0.obs;
  final isLoading = false.obs;
  PageController pageController = PageController(initialPage: 0);
  final currentVisibleIndex = RxInt(-1);
  final centeredIndex = 0.obs;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<UserPostReference>>? _savedPostsSub;
  final Map<int, GlobalKey> _postKeys = {};
  final UserPostLinkService _linkService = Get.put(UserPostLinkService());

  String? _currentUserId;
  List<UserPostReference> _latestRefs = const [];

  @override
  void onInit() {
    super.onInit();
    _bindAuth();
  }

  void _bindAuth() {
    _authSub = FirebaseAuth.instance.userChanges().listen((user) {
      _currentUserId = user?.uid;
      _savedPostsSub?.cancel();
      _clearLists();
      if (user != null) {
        _bindSaved(user.uid);
      }
    });
  }

  void _bindSaved(String userId) {
    _savedPostsSub = _linkService.listenSavedPosts(userId).listen((refs) {
      _latestRefs = refs;
      unawaited(_bootstrapSavedPosts(userId, refs));
    });
  }

  Future<void> _bootstrapSavedPosts(
    String userId,
    List<UserPostReference> refs,
  ) async {
    if (refs.isEmpty) {
      _clearLists();
      isLoading.value = false;
      return;
    }

    final cached = await _linkService.fetchSavedPosts(
      userId,
      refs,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      _applySavedPosts(cached);
      isLoading.value = false;
      unawaited(_hydrateSavedPosts(
        userId,
        refs,
        silent: true,
        forceRefresh: true,
      ));
      return;
    }

    await _hydrateSavedPosts(userId, refs);
  }

  Future<void> _hydrateSavedPosts(
    String userId,
    List<UserPostReference> refs, {
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent) {
      isLoading.value = true;
      _clearLists();
    }

    try {
      final posts = await _linkService.fetchSavedPosts(
        userId,
        refs,
        preferCache: !forceRefresh,
      );
      _applySavedPosts(posts);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _hydrateSavedPosts(userId, _latestRefs);
  }

  void _clearLists() {
    savedPhotos.clear();
    savedVideos.clear();
    savedAgendas.clear();
  }

  void _applySavedPosts(List<PostsModel> posts) {
    final nextPhotos = <PostsModel>[];
    final nextVideos = <PostsModel>[];
    final nextAgendas = <PostsModel>[];
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final post in posts) {
      if (post.deletedPost == true) continue;
      if (post.timeStamp > now) {
        continue;
      }

      if (post.hasPlayableVideo) {
        nextVideos.add(post);
      } else if (post.img.isNotEmpty) {
        nextPhotos.add(post);
      }
      nextAgendas.add(post);
    }

    savedPhotos.assignAll(nextPhotos);
    savedVideos.assignAll(nextVideos);
    savedAgendas.assignAll(nextAgendas);
  }

  void goToPage(int index) {
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  GlobalKey getPostKey(int index) {
    return _postKeys.putIfAbsent(index, () => GlobalObjectKey('post_$index'));
  }

  @override
  void onClose() {
    _savedPostsSub?.cancel();
    _authSub?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
