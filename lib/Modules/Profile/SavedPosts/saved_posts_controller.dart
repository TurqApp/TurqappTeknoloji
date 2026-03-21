import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Models/user_post_reference.dart';
import 'package:turqappv2/Services/user_post_link_service.dart';

class SavedPostsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);

  static SavedPostsController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(
      SavedPostsController(),
      permanent: permanent,
    );
  }

  static SavedPostsController? maybeFind() {
    if (!Get.isRegistered<SavedPostsController>()) return null;
    return Get.find<SavedPostsController>();
  }

  final RxList<PostsModel> savedAgendas = <PostsModel>[].obs;
  final RxList<PostsModel> savedPostsOnly = <PostsModel>[].obs;
  final RxList<PostsModel> savedSeries = <PostsModel>[].obs;

  final isLoading = false.obs;
  final PageController pageController = PageController(initialPage: 0);

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<UserPostReference>>? _savedPostsSub;
  final UserPostLinkService _linkService = UserPostLinkService.ensure();
  final PostRepository _postRepository = PostRepository.ensure();

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
      await _applySavedPosts(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'saved_posts:$userId',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(_hydrateSavedPosts(
          userId,
          refs,
          silent: true,
          forceRefresh: true,
        ));
      }
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
      final hasVisibleSnapshot = savedAgendas.isNotEmpty ||
          savedPostsOnly.isNotEmpty ||
          savedSeries.isNotEmpty;
      if (!hasVisibleSnapshot) {
        _clearLists();
      }
    }

    try {
      final posts = await _linkService.fetchSavedPosts(
        userId,
        refs,
        preferCache: !forceRefresh,
      );
      await _applySavedPosts(posts);
      SilentRefreshGate.markRefreshed('saved_posts:$userId');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  @override
  Future<void> refresh() async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _hydrateSavedPosts(userId, _latestRefs, forceRefresh: true);
  }

  void _clearLists() {
    savedAgendas.clear();
    savedPostsOnly.clear();
    savedSeries.clear();
  }

  Future<void> _applySavedPosts(List<PostsModel> posts) async {
    final nextAgendas = <PostsModel>[];
    final nextPostsOnly = <PostsModel>[];
    final nextSeries = <PostsModel>[];
    final now = DateTime.now().millisecondsSinceEpoch;
    final rootIdsInOrder = <String>[];
    final rootsById = <String, PostsModel>{};
    final singleIds = <String>{};
    final agendaIds = <String>{};

    for (final post in posts) {
      if (post.deletedPost == true) continue;
      if (post.timeStamp > now) continue;

      final isSeries = post.floodCount.toInt() > 1;
      if (isSeries) {
        final rootId = post.flood == true && post.mainFlood.trim().isNotEmpty
            ? post.mainFlood.trim()
            : post.docID;
        if (!rootIdsInOrder.contains(rootId)) {
          rootIdsInOrder.add(rootId);
        }
        if (rootId == post.docID) {
          rootsById[rootId] = post;
        }
        continue;
      }

      if (singleIds.add(post.docID)) {
        nextPostsOnly.add(post);
      }
    }

    final missingRootIds = rootIdsInOrder
        .where((rootId) => !rootsById.containsKey(rootId))
        .toList(growable: false);
    if (missingRootIds.isNotEmpty) {
      final fetchedRoots = await _postRepository.fetchPostsByIds(
        missingRootIds,
        preferCache: true,
      );
      rootsById.addAll(fetchedRoots);
    }

    for (final rootId in rootIdsInOrder) {
      final root = rootsById[rootId];
      if (root == null) continue;
      if (root.deletedPost == true || root.timeStamp > now) continue;
      nextSeries.add(root);
    }

    for (final post in posts) {
      if (post.deletedPost == true || post.timeStamp > now) continue;
      if (post.floodCount.toInt() > 1) continue;
      if (agendaIds.add(post.docID)) {
        nextAgendas.add(post);
      }
    }
    for (final post in nextSeries) {
      if (agendaIds.add(post.docID)) {
        nextAgendas.add(post);
      }
    }

    savedAgendas.assignAll(nextAgendas);
    savedPostsOnly.assignAll(nextPostsOnly);
    savedSeries.assignAll(nextSeries);
  }

  @override
  void onClose() {
    _savedPostsSub?.cancel();
    _authSub?.cancel();
    pageController.dispose();
    super.onClose();
  }
}
