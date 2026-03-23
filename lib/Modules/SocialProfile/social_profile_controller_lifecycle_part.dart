part of 'social_profile_controller.dart';

extension SocialProfileControllerLifecyclePart on SocialProfileController {
  void _handleLifecycleInit() {
    UserAnalyticsService.instance.trackFeatureUsage('social_profile_open');
    getUserData();
    getCounters();
    getUserStoryUserModelAndPrint(userID);
    getSocialMediaLinks();
    isFollowingCheck();
    _performLogProfileVisitIfNeeded();
    unawaited(_restoreCachedBuckets());
    _fetchPrimaryBuckets(initial: true);
    getReshares();
  }

  void _handleLifecycleClose() {
    scrollController.dispose();
    _userDocSub?.cancel();
    _resharesSub?.cancel();
  }

  bool _performIsPrivateContentBlockedFor(String? viewerUserId) {
    return gizliHesap.value &&
        takipEdiyorum.value == false &&
        viewerUserId != userID;
  }

  bool _performIsBlockedByCurrentViewer(String? otherUserId) {
    final other = (otherUserId ?? '').trim();
    if (other.isEmpty) return false;
    final currentBlocked = CurrentUserService.instance.blockedUserIds;
    return currentBlocked.contains(other);
  }

  String _performDisplayCounterValue({
    required String? viewerUserId,
    required num value,
  }) {
    if (isBlockedByCurrentViewer(viewerUserId)) {
      return "0";
    }
    return NumberFormatter.format(value.toInt());
  }
}
