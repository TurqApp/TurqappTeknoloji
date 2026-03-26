part of 'social_profile_controller.dart';

SocialProfileController _ensureSocialProfileController({
  required String userID,
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindSocialProfileController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SocialProfileController(userID: userID),
    tag: tag,
    permanent: permanent,
  );
}

SocialProfileController? _maybeFindSocialProfileController({String? tag}) =>
    Get.isRegistered<SocialProfileController>(tag: tag)
        ? Get.find<SocialProfileController>(tag: tag)
        : null;

class _SocialProfileShellState {
  _SocialProfileShellState({required String userID})
      : stats = _SocialProfileStatsState(),
        scrollState = _SocialProfileScrollState(),
        feedState = _SocialProfileFeedState(),
        profileState = _SocialProfileProfileState(userID);

  final _SocialProfileStatsState stats;
  final _SocialProfileScrollState scrollState;
  final _SocialProfileFeedState feedState;
  final _SocialProfileProfileState profileState;
}

extension SocialProfileControllerShellPart on SocialProfileController {
  _SocialProfileStatsState get _stats => _shellState.stats;
  _SocialProfileScrollState get _scrollState => _shellState.scrollState;
  _SocialProfileFeedState get _feedState => _shellState.feedState;
  _SocialProfileProfileState get _profileState => _shellState.profileState;
}
