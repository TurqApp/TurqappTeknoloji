part of 'my_statistic_controller.dart';

extension _MyStatisticControllerDataPart on MyStatisticController {
  void _bindUserDocCounters() {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    _userDocSub?.cancel();
    final userService = CurrentUserService.instance;
    final current = userService.currentUser;
    if (current != null && current.userID == uid) {
      totalPosts.value = current.counterOfPosts;
      followerCount.value = current.counterOfFollowers;
    }
    _userDocSub = userService.userStream.listen((user) {
      try {
        if (user == null || user.userID != uid) return;
        totalPosts.value = user.counterOfPosts;
        followerCount.value = user.counterOfFollowers;
      } catch (_) {}
    });
  }

  Future<void> _loadAll() async {
    isLoading.value = true;
    try {
      final uid = _currentUid;
      if (uid.isEmpty) {
        _reset();
        return;
      }
      await Future.wait([
        _loadFollowerCounts(uid),
        _loadPostCountsAndViews(uid),
        _loadStoryViewsAndVisits(uid),
      ]);
      _computeDerived();
      await _statsRepository.setStats(uid, _buildStatsSnapshot());
    } catch (_) {
      // Keep partial results.
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadFollowerCounts(String uid) async {
    try {
      final current = CurrentUserService.instance.currentUser;
      if (current != null && current.userID == uid) {
        followerCount.value = current.counterOfFollowers;
      }
      final result = await _statsRepository.fetchFollowerGrowth(uid);
      followerGrowth30d.value = result['followerGrowth30d'] ?? 0;
      followerGrowthPrev30d.value = result['followerGrowthPrev30d'] ?? 0;
    } catch (_) {
      // still show what we have
    }
  }

  Future<void> _loadPostCountsAndViews(String uid) async {
    try {
      final result = await _statsRepository.fetchPostStats(uid);
      totalPosts.value = result['totalPosts'] ?? 0;
      posts30d.value = result['posts30d'] ?? 0;
      totalPostViews.value = result['totalPostViews'] ?? 0;
      postViews30d.value = result['postViews30d'] ?? 0;
    } catch (_) {}
  }

  Future<void> _loadStoryViewsAndVisits(String uid) async {
    try {
      final result = await _statsRepository.fetchStoryStats(uid);
      stories30d.value = result['stories30d'] ?? 0;
      profileVisitsApprox.value = result['profileVisitsApprox'] ?? 0;
      totalStoryViews.value = result['totalStoryViews'] ?? 0;
    } catch (_) {}
  }
}
