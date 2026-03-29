part of 'story_row_controller.dart';

extension StoryRowControllerLoadPart on StoryRowController {
  Future<void> _bootstrapStoryRow() async {
    final myUid = _currentUid;
    if (myUid.isEmpty || !userService.hasAuthUser) {
      users.clear();
      return;
    }
    await _loadStoriesFromMiniCache();
    final bootstrapPlan = _storyRowApplicationService.buildBootstrapPlan(
      hasUsers: users.isNotEmpty,
      shouldSilentRefresh: SilentRefreshGate.shouldRefresh(
        'story:row:$myUid',
        minInterval: _storyRowSilentRefreshInterval,
      ),
    );
    if (bootstrapPlan.shouldSilentRefresh) {
      unawaited(loadStories(silentLoad: true, cacheFirst: true));
    }
  }

  Future<void> loadStories({
    int? limit,
    bool cacheFirst = false,
    bool silentLoad = false,
  }) async {
    final loadWatch = Stopwatch()..start();
    var cacheHit = false;
    final myUid = _currentUid;
    if (myUid.isEmpty || !userService.hasAuthUser) {
      users.clear();
      return;
    }
    try {
      if (!silentLoad) {
        isLoading.value = true;
      }
      if (!ContentPolicy.isConnected) {
        await _loadStoriesFromMiniCache(allowExpired: true);
        return;
      }
      final lim = limit ?? initialLimit;

      if (myUid.isNotEmpty) {
        final now = DateTime.now();
        final shouldCleanup =
            _storyRowApplicationService.shouldRunExpireCleanup(
          lastCleanupAt: _lastExpireCleanupAt,
          now: now,
          interval: _storyRowExpireCleanupInterval,
        );
        if (shouldCleanup) {
          _lastExpireCleanupAt = now;
          await _storyRepository.markExpiredStoriesDeleted(myUid);
        }
      }

      final result = await _storyRepository.fetchStoryUsers(
        limit: lim,
        cacheFirst: cacheFirst,
        currentUid: myUid,
        blockedUserIds: userService.blockedUserIds,
      );
      cacheHit = result.cacheHit;
      final tempList = [...result.users];

      StoryUserModel? myStoryUser;
      if (myUid.isNotEmpty) {
        myStoryUser = tempList.firstWhereOrNull((u) => u.userID == myUid);
        if (myStoryUser == null) {
          final data = await _userCache.getProfile(
            myUid,
            preferCache: true,
            cacheOnly: !ContentPolicy.isConnected,
          );
          if (data != null) {
            myStoryUser = StoryUserModel(
              nickname: _resolveStoryNickname(data),
              avatarUrl: _resolveAvatar(data),
              fullName: "${data['firstName'] ?? ""} ${data['lastName'] ?? ""}",
              userID: myUid,
              stories: const [],
            );
          }
        }
        tempList.removeWhere((u) => u.userID == myUid);
      }

      bool allSeen(StoryUserModel u) {
        if (u.stories.isEmpty) return true;
        if (!userService.hasReadStory(u.userID)) {
          return false;
        }

        final lastSeen = userService.getStoryReadTime(u.userID);
        if (lastSeen == null) return false;

        for (final story in u.stories) {
          if (story.createdAt.millisecondsSinceEpoch > lastSeen) {
            return false;
          }
        }
        return true;
      }

      users.value = _storyRowApplicationService.buildOrderedUsers(
        fetchedUsers: tempList,
        currentUid: myUid,
        currentUserStory: myStoryUser,
        isAllSeen: allSeen,
      );
      unawaited(_warmVisibleAvatarFiles(users));
      if (_shouldLogDebug && myUid.isNotEmpty) {
        final me = users.firstWhereOrNull((u) => u.userID == myUid);
        debugPrint(
          "Story row self state: exists=${me != null} stories=${me?.stories.length ?? 0}",
        );
      }
      if (myUid.isNotEmpty) {
        unawaited(
          _storyRepository.saveStoryRowCache(users, ownerUid: myUid),
        );
        SilentRefreshGate.markRefreshed('story:row:$myUid');
      }
    } catch (e) {
      debugPrint("LoadStories error: $e");
      if (users.isEmpty) {
        await _loadStoriesFromMiniCache();
      }
    } finally {
      _ensureMyUserPlaceholder();
      loadWatch.stop();
      if (cacheFirst) {
        unawaited(UserAnalyticsService.instance.trackCachePerformance(
          cacheHit: cacheHit,
          loadTimeMs: loadWatch.elapsedMilliseconds,
        ));
      }
      if (!silentLoad) {
        isLoading.value = false;
      }
    }
  }

  void _scheduleBackgroundFullLoad() {
    if (_backgroundScheduled) return;
    if (!ContentPolicy.allowBackgroundRefresh(ContentScreenKind.story)) return;
    _backgroundScheduled = true;
    _backgroundFullLoadTimer?.cancel();
    _backgroundFullLoadTimer = Timer(const Duration(seconds: 12), () async {
      _backgroundFullLoadTimer = null;
      try {
        if (isClosed ||
            !ContentPolicy.allowBackgroundRefresh(ContentScreenKind.story)) {
          return;
        }
        await loadStories(limit: fullLimit, silentLoad: true);
      } catch (_) {}
      if (!isClosed) {
        _backgroundScheduled = false;
      }
    });
  }
}
