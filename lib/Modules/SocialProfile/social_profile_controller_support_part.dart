part of 'social_profile_controller.dart';

final UserRepository _userRepository = UserRepository.ensure();
final RuntimeInvariantGuard _invariantGuard = ensureRuntimeInvariantGuard();
final FollowRepository _followRepository = ensureFollowRepository();
final SocialMediaLinksRepository _socialLinksRepository =
    SocialMediaLinksRepository.ensure();
final StoryRepository _storyRepository = StoryRepository.ensure();
final UserSubcollectionRepository _userSubcollectionRepository =
    ensureUserSubcollectionRepository();
final UserPostLinkService _linkService = UserPostLinkService.ensure();
final ProfileRepository _profileRepository = ensureProfileRepository();
final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
const int _socialProfilePageSize = 12;

const Duration _followCheckCacheTtl = Duration(seconds: 20);
const Duration _counterCacheTtl = Duration(seconds: 30);
const Duration _cacheStaleRetention = Duration(minutes: 3);
const int _maxCacheEntries = 500;
final Map<String, _SocialFollowCheckCacheEntry> _followCheckCache =
    <String, _SocialFollowCheckCacheEntry>{};
final Map<String, _SocialCounterCacheEntry> _counterCache =
    <String, _SocialCounterCacheEntry>{};

String _resolveNickname(
  Map<String, dynamic> raw,
  Map<String, dynamic> profile,
) {
  final nickname =
      (raw['nickname'] ?? profile['nickname'] ?? '').toString().trim();
  final username =
      (raw['username'] ?? profile['username'] ?? '').toString().trim();
  final displayName =
      (raw['displayName'] ?? profile['displayName'] ?? '').toString().trim();
  if (nickname.isNotEmpty) return nickname;
  if (username.isNotEmpty) return username;
  return displayName;
}

extension SocialProfileControllerSupportPart on SocialProfileController {
  int get pageSize => _socialProfilePageSize;
  int get pageSizePhoto => _socialProfilePageSize;
  int get pageSizeScheduled => _socialProfilePageSize;

  int resolveResumeCenteredIndex() => _performResolveResumeCenteredIndex();

  void resumeCenteredPost() => _performResumeCenteredPost();

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) =>
      _performOnPostVisibilityChanged(modelIndex, visibleFraction);

  void capturePendingCenteredEntry({
    int? preferredIndex,
    PostsModel? model,
    bool isReshare = false,
  }) =>
      _performCapturePendingCenteredEntry(
        preferredIndex: preferredIndex,
        model: model,
        isReshare: isReshare,
      );
}
