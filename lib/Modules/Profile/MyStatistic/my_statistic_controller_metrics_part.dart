part of 'my_statistic_controller.dart';

extension _MyStatisticControllerMetricsPart on MyStatisticController {
  void _reset() {
    totalPostViews.value = 0;
    totalStoryViews.value = 0;
    totalPosts.value = 0;
    followerCount.value = 0;
    postViews30d.value = 0;
    posts30d.value = 0;
    stories30d.value = 0;
    followerGrowth30d.value = 0;
    followerGrowthPrev30d.value = 0;
    followerGrowthPct.value = 0.0;
    postViewRatePct.value = 0.0;
    profileVisitsApprox.value = 0;
  }

  Future<void> _loadWarmCache() async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final cached = await _statsRepository.getStats(uid, preferCache: true);
    if (cached == null || cached.isEmpty) return;
    _applyStatsSnapshot(cached);
    isLoading.value = false;
  }

  Map<String, dynamic> _buildStatsSnapshot() {
    return <String, dynamic>{
      'totalPostViews': totalPostViews.value,
      'totalStoryViews': totalStoryViews.value,
      'totalPosts': totalPosts.value,
      'followerCount': followerCount.value,
      'postViews30d': postViews30d.value,
      'posts30d': posts30d.value,
      'stories30d': stories30d.value,
      'followerGrowth30d': followerGrowth30d.value,
      'followerGrowthPrev30d': followerGrowthPrev30d.value,
      'followerGrowthPct': followerGrowthPct.value,
      'postViewRatePct': postViewRatePct.value,
      'profileVisitsApprox': profileVisitsApprox.value,
    };
  }

  void _applyStatsSnapshot(Map<String, dynamic> data) {
    int asInt(String key) => ((data[key] ?? 0) as num).toInt();
    double asDouble(String key) => ((data[key] ?? 0) as num).toDouble();

    totalPostViews.value = asInt('totalPostViews');
    totalStoryViews.value = asInt('totalStoryViews');
    totalPosts.value = asInt('totalPosts');
    followerCount.value = asInt('followerCount');
    postViews30d.value = asInt('postViews30d');
    posts30d.value = asInt('posts30d');
    stories30d.value = asInt('stories30d');
    followerGrowth30d.value = asInt('followerGrowth30d');
    followerGrowthPrev30d.value = asInt('followerGrowthPrev30d');
    followerGrowthPct.value = asDouble('followerGrowthPct');
    postViewRatePct.value = asDouble('postViewRatePct');
    profileVisitsApprox.value = asInt('profileVisitsApprox');
  }

  void _computeDerived() {
    final prev = followerGrowthPrev30d.value;
    final curr = followerGrowth30d.value;
    if (prev > 0) {
      followerGrowthPct.value = ((curr - prev) / prev) * 100.0;
    } else {
      followerGrowthPct.value = curr > 0 ? 100.0 : 0.0;
    }

    final posts = totalPosts.value;
    final followers = followerCount.value;
    if (posts > 0 && followers > 0) {
      final avgViews = totalPostViews.value / posts;
      final pct = (avgViews / followers) * 100.0;
      postViewRatePct.value = pct.clamp(0.0, 9999.0);
    } else {
      postViewRatePct.value = 0.0;
    }
  }
}
