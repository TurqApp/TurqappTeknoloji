part of 'social_profile_controller.dart';

class _SocialFollowCheckCacheEntry {
  final bool isFollowing;
  final DateTime cachedAt;

  const _SocialFollowCheckCacheEntry({
    required this.isFollowing,
    required this.cachedAt,
  });
}

class _SocialCounterCacheEntry {
  final int followers;
  final int followings;
  final DateTime cachedAt;

  const _SocialCounterCacheEntry({
    required this.followers,
    required this.followings,
    required this.cachedAt,
  });
}

final VisibilityPolicyService _visibilityPolicy =
    VisibilityPolicyService.ensure();
