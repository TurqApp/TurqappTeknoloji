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
    _primeRecommendedUserCaches(filtered, source: 'local_cache');
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
      _primeRecommendedUserCaches(filtered, source: 'load');
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

  void _primeRecommendedUserCaches(
    List<RecommendedUserModel> users, {
    required String source,
  }) {
    if (users.isEmpty) return;
    debugPrint(
      '[RecommendedUsers] status=cache_prime_scheduled source=$source '
      'count=${users.length}',
    );
    unawaited(_primeRecommendedUserCachesImpl(users, source: source));
  }

  Future<void> _primeRecommendedUserCachesImpl(
    List<RecommendedUserModel> users, {
    required String source,
  }) async {
    var metaSeeded = 0;
    try {
      final resolver = UserSummaryResolver.ensure();
      for (final user in users) {
        final uid = user.userID.trim();
        if (uid.isEmpty) continue;
        try {
          await resolver.seedRaw(uid, _recommendedUserProfileSeed(user));
          metaSeeded++;
        } catch (_) {}
      }
    } catch (_) {}

    final avatarWarmed = await _warmRecommendedUserAvatars(users);
    debugPrint(
      '[RecommendedUsers] status=cache_prime_done source=$source '
      'count=${users.length} metaSeeded=$metaSeeded '
      'avatarWarmed=$avatarWarmed',
    );
  }

  Future<int> _warmRecommendedUserAvatars(
    List<RecommendedUserModel> users,
  ) async {
    if (QALabMode.integrationSmokeRun) return 0;
    final urls = <String>[];
    final seen = <String>{};
    for (final user in users) {
      final url = user.avatarUrl.trim();
      if (url.isEmpty || isDefaultAvatarUrl(url) || !seen.add(url)) continue;
      if (!_cachePrimedAvatarUrls.add(url)) continue;
      urls.add(url);
    }
    if (urls.isEmpty) return 0;

    var warmed = 0;
    var nextIndex = 0;
    final workerCount = urls.length < 8 ? urls.length : 8;

    Future<void> worker() async {
      while (true) {
        final index = nextIndex;
        if (index >= urls.length) return;
        nextIndex++;
        final url = urls[index];
        try {
          await TurqAvatarCacheManager.warmUrl(url).timeout(
            const Duration(seconds: 6),
          );
          warmed++;
        } catch (_) {}
      }
    }

    await Future.wait(
      List<Future<void>>.generate(workerCount, (_) => worker()),
    );
    return warmed;
  }

  Map<String, dynamic> _recommendedUserProfileSeed(
    RecommendedUserModel user,
  ) {
    final firstName = user.firstName.trim();
    final lastName = user.lastName.trim();
    final fullName = <String>[
      if (firstName.isNotEmpty) firstName,
      if (lastName.isNotEmpty) lastName,
    ].join(' ').trim();
    final nickname = user.nickname.trim();
    return <String, dynamic>{
      'userID': user.userID.trim(),
      'firstName': firstName,
      'lastName': lastName,
      'fullName': fullName,
      'displayName': fullName.isNotEmpty ? fullName : nickname,
      'nickname': nickname,
      'username': nickname,
      'usernameLower': nickname.toLowerCase(),
      'avatarUrl': user.avatarUrl.trim(),
      'bio': user.bio.trim(),
      'rozet': user.rozet.trim(),
    };
  }
}
