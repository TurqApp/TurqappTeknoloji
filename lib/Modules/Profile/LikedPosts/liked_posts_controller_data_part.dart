part of 'liked_posts_controller.dart';

extension LikedPostsControllerDataPart on LikedPostControllers {
  void _handleOnInit() {
    _bindAuth();
  }

  void _handleOnClose() {
    _likedSub?.cancel();
    _authSub?.cancel();
    pageController.dispose();
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
        minInterval: LikedPostControllers._silentRefreshInterval,
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
      if (all.isEmpty) {
        all.clear();
      }
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

  Future<void> _refreshLikedPosts() async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _hydrate(userId, _latestRefs, forceRefresh: true);
  }

  void _applyPosts(List<PostsModel> posts) {
    final visiblePosts = posts.where((p) => p.deletedPost != true).toList();
    all.assignAll(visiblePosts);
  }
}
