part of 'profile_controller.dart';

final userService = CurrentUserService.instance;
final ProfileRepository _profileRepository = ensureProfileRepository();
final ProfilePostsSnapshotRepository _profileSnapshotRepository =
    ProfilePostsSnapshotRepository.ensure();
final ProfileRenderCoordinator _profileRenderCoordinator =
    ensureProfileRenderCoordinator();
final FollowRepository _followRepository = ensureFollowRepository();
final VisibilityPolicyService _visibilityPolicy =
    VisibilityPolicyService.ensure();
final UserRepository _userRepository = UserRepository.ensure();
final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
final RuntimeInvariantGuard _invariantGuard = ensureRuntimeInvariantGuard();
final SocialMediaLinksRepository _socialLinksRepository =
    SocialMediaLinksRepository.ensure();
final UserPostLinkService _linkService = UserPostLinkService.ensure();
const int _profilePageLimit = 10;

extension ProfileControllerSupportPart on ProfileController {
  int get postLimit => _profilePageLimit;
  int get scheduledLimit => _profilePageLimit;
  int get postLimitPhotos => _profilePageLimit;
  int get postLimitVideos => _profilePageLimit;

  Future<void> onPrimarySurfaceVisible() => prepareStartupSurface(
        allowBackgroundRefresh:
            ContentPolicy.allowBackgroundRefresh(ContentScreenKind.profile),
      );

  Future<void> prepareStartupSurface({bool? allowBackgroundRefresh}) =>
      _performPrepareStartupSurface(
        allowBackgroundRefresh: allowBackgroundRefresh,
      );

  Future<void> persistStartupShard() => _persistProfileStartupShard();

  String? get _resolvedActiveUid => _performResolvedActiveUid();

  ScrollController scrollControllerForSelection(int selection) =>
      _performScrollControllerForSelection(selection);

  ScrollController get currentScrollController =>
      _performCurrentScrollController();

  ScrollPosition? get currentScrollPosition => _performCurrentScrollPosition();

  double get currentScrollOffset => _performCurrentScrollOffset();

  double get lastObservedScrollOffset => _lastObservedOffset;
  set lastObservedScrollOffset(double value) => _lastObservedOffset = value;

  bool get hasStartupPlaybackLock =>
      (_startupLockedIdentity?.trim().isNotEmpty ?? false);

  bool get hasStartupScrollStarted => _startupScrollStartedAt != null;

  void markStartupScrollBegan() {
    _startupLockedIdentity = null;
    _startupScrollStartedAt = DateTime.now();
  }

  void clearStartupScrollTracking() {
    _startupScrollStartedAt = null;
  }

  Future<void> animateCurrentSelectionToTop() =>
      _performAnimateCurrentSelectionToTop();

  void resetSurfaceForTabTransition() => _performResetSurfaceForTabTransition();

  int resolveResumeCenteredIndex() => _performResolveResumeCenteredIndex();

  void resumeCenteredPost() => _performResumeCenteredPost();

  void ensureCenteredPlaybackForCurrentSelection() =>
      _performEnsureCenteredPlaybackForIndex(centeredIndex.value);

  void bootstrapFeedPlaybackAfterDataChange() =>
      _performBootstrapFeedPlaybackAfterDataChange();

  void capturePendingCenteredEntry({int? preferredIndex}) =>
      _performCapturePendingCenteredEntry(preferredIndex: preferredIndex);

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) =>
      _performOnPostVisibilityChanged(modelIndex, visibleFraction);
}
