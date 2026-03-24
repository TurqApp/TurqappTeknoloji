import 'dart:async';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/profile_stats_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_statistic_controller_metrics_part.dart';

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
}
