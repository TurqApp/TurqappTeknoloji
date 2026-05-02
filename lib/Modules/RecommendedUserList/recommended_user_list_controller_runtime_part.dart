part of 'recommended_user_list_controller.dart';

extension _RecommendedUserListControllerRuntimeX
    on RecommendedUserListController {
  void _preloadInBackground() {
    Future.microtask(() async {
      try {
        await ensureLoaded(limit: usersWarmCount);
      } catch (_) {}
    });
  }

  Future<bool> _hydrateFromLocalCacheOnly({
    required int requiredCount,
  }) async {
    final currentUserId = CurrentUserService.instance.effectiveUserId;
    final cached =
        await ensureRecommendedUsersRepository().loadCachedCandidates(
      limit: requiredCount < usersWarmCount ? usersWarmCount : requiredCount,
      allowStale: true,
    );
    if (cached.isEmpty) {
      debugPrint(
        '[RecommendedUsers] status=local_cache_miss required=$requiredCount',
      );
      return false;
    }
    final filtered = _filterCandidates(cached, currentUserId);
    if (filtered.isEmpty) {
      debugPrint(
        '[RecommendedUsers] status=local_cache_filtered_empty required=$requiredCount '
        'candidateCount=${cached.length}',
      );
      return false;
    }
    list.assignAll(filtered);
    debugPrint(
      '[RecommendedUsers] status=local_cache_applied required=$requiredCount '
      'candidateCount=${cached.length} filteredCount=${filtered.length}',
    );
    return true;
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
      return RecommendedUserListController.hasAllowedRecommendedUserRozet(
        user.rozet,
      );
    }).map((user) {
      final sanitizedRozet =
          RecommendedUserListController.sanitizeRecommendedUserRozet(
        user.rozet,
      );
      return RecommendedUserModel(
        userID: user.userID,
        firstName: user.firstName,
        lastName: user.lastName,
        avatarUrl: user.avatarUrl,
        nickname: user.nickname,
        bio: user.bio,
        rozet: sanitizedRozet,
      );
    }).toList(growable: false);
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

  Future<void> getUsers({
    int? limit,
    bool allowFullRefill = true,
  }) async {
    final requiredCount = limit ?? usersWarmCount;
    if (_isCacheValid() && _hasEnoughUsers(requiredCount)) return;
    if (isLoading.value) return;

    isLoading.value = true;
    hasError.value = false;

    try {
      final currentUserId = CurrentUserService.instance.effectiveUserId;
      await getFollowing();
      final fetchLimit = requiredCount <= usersWarmCount
          ? usersFetchWarm
          : (requiredCount <= usersReadyCount
              ? usersLimitInitial
              : requiredCount);
      debugPrint(
        '[RecommendedUsers] status=load_start required=$requiredCount '
        'fetchLimit=$fetchLimit currentCount=${list.length} '
        'followingCount=${takipEdilenler.length}',
      );

      var candidates = await ensureRecommendedUsersRepository()
          .fetchCandidates(limit: fetchLimit, preferCache: true)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw TimeoutException('Kullanıcılar yüklenemedi'),
          );

      var filtered = _filterCandidates(candidates, currentUserId);
      debugPrint(
        '[RecommendedUsers] status=filter_pass candidateCount=${candidates.length} '
        'filteredCount=${filtered.length} required=$requiredCount',
      );
      if (allowFullRefill &&
          filtered.length < requiredCount &&
          fetchLimit < usersLimitFull) {
        candidates = await ensureRecommendedUsersRepository()
            .fetchCandidates(limit: usersLimitFull, preferCache: false)
            .timeout(
              const Duration(seconds: 10),
              onTimeout: () =>
                  throw TimeoutException('Kullanıcılar yüklenemedi'),
            );
        filtered = _filterCandidates(candidates, currentUserId);
        debugPrint(
          '[RecommendedUsers] status=full_refill candidateCount=${candidates.length} '
          'filteredCount=${filtered.length} required=$requiredCount',
        );
      }

      list.assignAll(filtered);
      _lastLoadTime = DateTime.now();
    } catch (error) {
      debugPrint('[RecommendedUsers] status=load_fail error=$error');
      hasError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> ensureLoaded({int? limit}) async {
    final requiredCount = limit ?? usersWarmCount;
    if (_isCacheValid() && _hasEnoughUsers(requiredCount)) return;
    if (loadedOnce && _hasEnoughUsers(requiredCount)) {
      _scheduleBackgroundUsersLoad(
        delay: const Duration(seconds: 4),
        limit: usersReadyCount,
      );
      return;
    }

    final hydratedLocally = await _hydrateFromLocalCacheOnly(
      requiredCount: requiredCount,
    );
    loadedOnce = true;
    _scheduleBackgroundUsersLoad(
      delay: hydratedLocally
          ? const Duration(seconds: 2)
          : const Duration(milliseconds: 900),
      limit: requiredCount,
      allowFullRefill: true,
    );
  }

  void _scheduleBackgroundUsersLoad({
    Duration delay = const Duration(seconds: 5),
    int? limit,
    bool allowFullRefill = true,
  }) {
    if (_bgScheduled) return;
    _bgScheduled = true;
    final requiredCount = limit ?? usersLimitFull;
    debugPrint(
      '[RecommendedUsers] status=background_scheduled delayMs=${delay.inMilliseconds} '
      'required=$requiredCount allowFullRefill=$allowFullRefill',
    );
    Future.delayed(delay, () async {
      try {
        if (!_isCacheValid()) {
          debugPrint(
            '[RecommendedUsers] status=background_load_start required=$requiredCount '
            'allowFullRefill=$allowFullRefill currentCount=${list.length}',
          );
          await getUsers(
            limit: requiredCount,
            allowFullRefill: allowFullRefill,
          );
        }
      } catch (_) {
      } finally {
        _bgScheduled = false;
      }
    });
  }
}
