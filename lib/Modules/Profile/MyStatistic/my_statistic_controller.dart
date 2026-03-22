import 'dart:async';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_stats_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class MyStatisticController extends GetxController {
  static MyStatisticController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyStatisticController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyStatisticController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyStatisticController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyStatisticController>(tag: tag);
  }

  final ProfileStatsRepository _statsRepository =
      ProfileStatsRepository.ensure();
  final isLoading = true.obs;
  StreamSubscription<dynamic>? _userDocSub;

  // Core stats
  final totalPostViews = 0.obs;
  final totalStoryViews = 0.obs;
  final totalPosts = 0.obs;
  final followerCount = 0.obs;
  // 30-day stats
  final postViews30d = 0.obs;
  final posts30d = 0.obs;
  final stories30d = 0.obs;

  // Growth metrics (last 30 days)
  final followerGrowth30d = 0.obs;
  final followerGrowthPrev30d = 0.obs;
  final followerGrowthPct = 0.0.obs; // percent vs previous period

  // Post view rate vs followers (avg views per post / followers)
  final postViewRatePct = 0.0.obs;

  // Approx profile visits (story views in last 30d)
  final profileVisitsApprox = 0.obs;

  String get _currentUid => CurrentUserService.instance.effectiveUserId;

  // Controls
  @override
  void onInit() {
    super.onInit();
    _loadWarmCache();
    _loadAll();
    _bindUserDocCounters();
  }

  @override
  Future<void> refresh() async {
    await _loadAll();
  }

  @override
  void onClose() {
    _userDocSub?.cancel();
    super.onClose();
  }

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

  void _computeDerived() {
    // Follower growth percent vs previous 30 days
    final prev = followerGrowthPrev30d.value;
    final curr = followerGrowth30d.value;
    if (prev > 0) {
      followerGrowthPct.value = ((curr - prev) / prev) * 100.0;
    } else {
      followerGrowthPct.value = curr > 0 ? 100.0 : 0.0;
    }

    // Post view rate: avg views per post relative to followers
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
