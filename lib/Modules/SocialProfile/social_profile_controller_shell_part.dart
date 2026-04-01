part of 'social_profile_controller.dart';

extension SocialProfileControllerShellPart on SocialProfileController {
  _SocialProfileStatsState get _stats => _shellState.stats;
  _SocialProfileScrollState get _scrollState => _shellState.scrollState;
  _SocialProfileFeedState get _feedState => _shellState.feedState;
  _SocialProfileProfileState get _profileState => _shellState.profileState;
}
