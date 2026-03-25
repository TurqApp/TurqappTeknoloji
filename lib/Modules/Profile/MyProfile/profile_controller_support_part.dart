part of 'profile_controller.dart';

final userService = CurrentUserService.instance;
final ProfileRepository _profileRepository = ProfileRepository.ensure();
final ProfilePostsSnapshotRepository _profileSnapshotRepository =
    ProfilePostsSnapshotRepository.ensure();
final ProfileRenderCoordinator _profileRenderCoordinator =
    ProfileRenderCoordinator.ensure();
final FollowRepository _followRepository = FollowRepository.ensure();
final VisibilityPolicyService _visibilityPolicy =
    VisibilityPolicyService.ensure();
final UserRepository _userRepository = UserRepository.ensure();
final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
final RuntimeInvariantGuard _invariantGuard = RuntimeInvariantGuard.ensure();
final SocialMediaLinksRepository _socialLinksRepository =
    SocialMediaLinksRepository.ensure();

extension ProfileControllerSupportPart on ProfileController {
  String? get _resolvedActiveUid => _performResolvedActiveUid();

  ScrollController scrollControllerForSelection(int selection) =>
      _performScrollControllerForSelection(selection);

  ScrollController get currentScrollController =>
      _performCurrentScrollController();

  ScrollPosition? get currentScrollPosition => _performCurrentScrollPosition();

  double get currentScrollOffset => _performCurrentScrollOffset();

  Future<void> animateCurrentSelectionToTop() =>
      _performAnimateCurrentSelectionToTop();

  void resetSurfaceForTabTransition() => _performResetSurfaceForTabTransition();

  int resolveResumeCenteredIndex() => _performResolveResumeCenteredIndex();

  void resumeCenteredPost() => _performResumeCenteredPost();

  void capturePendingCenteredEntry({int? preferredIndex}) =>
      _performCapturePendingCenteredEntry(preferredIndex: preferredIndex);

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) =>
      _performOnPostVisibilityChanged(modelIndex, visibleFraction);
}
