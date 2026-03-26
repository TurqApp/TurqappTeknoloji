part of 'recommended_user_list_controller.dart';

extension _RecommendedUserListControllerRuntimeX
    on RecommendedUserListController {
  void _preloadInBackground() {
    Future.microtask(() async {
      try {
        await ensureLoaded(limit: usersReadyCount);
      } catch (_) {}
    });
  }

  bool _isCacheValid() {
    if (_lastLoadTime == null) return false;
    return DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration;
  }

  bool _isFollowingCacheValid() {
    if (_lastFollowingLoadTime == null) return false;
    return DateTime.now().difference(_lastFollowingLoadTime!) <
        _followingCacheValidDuration;
  }

  bool _hasEnoughUsers(int requiredCount) {
    return list.length >= requiredCount;
  }

  List<RecommendedUserModel> _filterCandidates(
    List<RecommendedUserModel> candidates,
    String currentUserId,
  ) {
    return candidates.where((user) {
      if (user.userID == currentUserId) return false;
      if (takipEdilenler.contains(user.userID)) return false;
      final normalizedRozet = normalizeRozetValue(user.rozet);
      return normalizedRozet.isNotEmpty &&
          normalizedRozet != 'kirmizi' &&
          normalizedRozet != 'gri';
    }).toList()
      ..shuffle();
  }

  Future<void> getFollowing() async {
    if (_isFollowingCacheValid() && takipEdilenler.isNotEmpty) return;
    if (isLoadingFollowing) return;
    isLoadingFollowing = true;

    try {
      final currentUserId = CurrentUserService.instance.effectiveUserId;
      final ids = await _visibilityPolicy.loadViewerFollowingIds(
        viewerUserId: currentUserId,
        preferCache: true,
      );
      takipEdilenler.assignAll(ids.toList());
      hasMoreFollowing = false;
      _lastFollowingLoadTime = DateTime.now();
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoadingFollowing = false;
    }
  }

  Future<void> getUsers({int? limit}) async {
    final requiredCount = limit ?? usersLimitFull;
    if (_isCacheValid() && _hasEnoughUsers(requiredCount)) return;
    if (isLoading.value) return;

    isLoading.value = true;
    hasError.value = false;

    try {
      final currentUserId = CurrentUserService.instance.effectiveUserId;
      await getFollowing();
      final fetchLimit =
          requiredCount <= usersReadyCount ? usersLimitInitial : requiredCount;

      var candidates = await RecommendedUsersRepository.ensure()
          .fetchCandidates(limit: fetchLimit, preferCache: true)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Kullanıcılar yüklenemedi'),
          );

      var filtered = _filterCandidates(candidates, currentUserId);
      if (filtered.length < requiredCount && fetchLimit < usersLimitFull) {
        candidates = await RecommendedUsersRepository.ensure()
            .fetchCandidates(limit: usersLimitFull, preferCache: false)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw TimeoutException('Kullanıcılar yüklenemedi'),
            );
        filtered = _filterCandidates(candidates, currentUserId);
      }

      list.assignAll(filtered);
      _lastLoadTime = DateTime.now();
    } catch (_) {
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> ensureLoaded({int? limit}) async {
    final requiredCount = limit ?? usersReadyCount;
    if (_isCacheValid() && _hasEnoughUsers(requiredCount)) return;
    if (loadedOnce && _hasEnoughUsers(requiredCount)) {
      _scheduleBackgroundUsersLoad();
      return;
    }

    await getUsers(limit: requiredCount);
    loadedOnce = true;
    _scheduleBackgroundUsersLoad();
  }

  void _scheduleBackgroundUsersLoad() {
    if (_bgScheduled) return;
    _bgScheduled = true;
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        if (!_isCacheValid()) {
          await getUsers(limit: usersLimitFull);
        }
      } catch (_) {
      } finally {
        _bgScheduled = false;
      }
    });
  }
}
