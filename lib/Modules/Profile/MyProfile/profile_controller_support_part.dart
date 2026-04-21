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
const int _profilePageLimit = 20;
const int _profileSecondaryPageLimit = 20;
const int _profileFeedLoadTriggerRemaining = 5;

extension ProfileControllerSupportPart on ProfileController {
  int get postLimit => _profilePageLimit;
  int get scheduledLimit => _profileSecondaryPageLimit;
  int get postLimitPhotos => _profileSecondaryPageLimit;
  int get postLimitVideos => _profileSecondaryPageLimit;
  int get feedLoadTriggerRemaining => _profileFeedLoadTriggerRemaining;

  Future<void> onPrimarySurfaceVisible() => prepareStartupSurface(
        allowBackgroundRefresh:
            ContentPolicy.allowBackgroundRefresh(ContentScreenKind.profile),
      );

  void setPrimarySurfaceActive(bool value) =>
      _performSetPrimarySurfaceActive(value);

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

  void promoteUploadedPosts(List<PostsModel> posts) {
    if (posts.isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    void upsertBucket(RxList<PostsModel> bucket, PostsModel post) {
      final existingIndex = bucket.indexWhere((p) => p.docID == post.docID);
      if (existingIndex == -1) {
        final current = List<PostsModel>.from(bucket);
        current.insert(0, post);
        bucket.value = current;
        return;
      }
      if (existingIndex > 0) {
        final current = List<PostsModel>.from(bucket);
        final existing = current.removeAt(existingIndex);
        current.insert(0, existing);
        bucket.value = current;
      }
    }

    for (final post in posts.reversed) {
      if (post.deletedPost == true) continue;
      if (post.video.trim().isNotEmpty && !post.hasPlayableVideo) continue;

      final isScheduled = post.scheduledAt.toInt() > 0;
      if (isScheduled) {
        upsertBucket(scheduledPosts, post);
      }

      if (post.timeStamp <= nowMs) {
        upsertBucket(allPosts, post);
        if (post.video.trim().isEmpty) {
          upsertBucket(photos, post);
        }
        if (post.hasPlayableVideo) {
          upsertBucket(videos, post);
        }
      }
    }

    bootstrapFeedPlaybackAfterDataChange();
  }

  void capturePendingCenteredEntry({int? preferredIndex}) =>
      _performCapturePendingCenteredEntry(preferredIndex: preferredIndex);

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) =>
      _performOnPostVisibilityChanged(modelIndex, visibleFraction);
}
