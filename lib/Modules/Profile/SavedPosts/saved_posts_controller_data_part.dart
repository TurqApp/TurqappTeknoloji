part of 'saved_posts_controller.dart';

extension SavedPostsControllerDataPart on SavedPostsController {
  void _handleOnInit() {
    _bindAuth();
  }

  void _handleOnClose() {
    _savedPostsSub?.cancel();
    _authSub?.cancel();
    pageController.dispose();
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
        minInterval: SavedPostsController._silentRefreshInterval,
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

  Future<void> _refreshSavedPosts() async {
    final userId = _currentUserId;
    if (userId == null) return;
    await _hydrateSavedPosts(userId, _latestRefs, forceRefresh: true);
  }

  void _clearLists() {
    savedAgendas.clear();
    savedPostsOnly.clear();
    savedSeries.clear();
  }
}
