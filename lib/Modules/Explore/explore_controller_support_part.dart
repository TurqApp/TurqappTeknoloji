part of 'explore_controller.dart';

const double _verticalExploreAspectMax = 0.7;
const String _recentSearchUsersCachePrefix = 'explore_recent_search_users_v1_';
const int _recentSearchUsersLimit = 100;
const Duration _searchDebounceDuration = Duration(milliseconds: 300);

extension _ExploreControllerSupportX on ExploreController {
  UserProfileCacheService get _userCache => ensureUserProfileCacheService();

  UserSubcollectionRepository get _subcollectionRepository =>
      ensureUserSubcollectionRepository();

  TopTagsRepository get _topTagsRepository => ensureTopTagsRepository();

  ExploreRepository get _exploreRepository => ExploreRepository.ensure();

  VisibilityPolicyService get _visibilityPolicy =>
      VisibilityPolicyService.ensure();

  void _syncScrollToTopVisibility(double offset) =>
      _performSyncScrollToTopVisibility(offset);

  String floodSeriesInstanceTag(String docId) => 'explore_series_$docId';

  void disposeFloodContentController(String docId) =>
      _performDisposeFloodContentController(docId);

  void _updateFloodVisibleIndex() => _performUpdateFloodVisibleIndex();

  int resolveFloodSeriesFocusIndex() => _performResolveFloodSeriesFocusIndex();

  void restoreFloodSeriesFocus() => _performRestoreFloodSeriesFocus();

  void suspendExplorePreview({int focusIndex = -1}) =>
      _performSuspendExplorePreview(focusIndex: focusIndex);

  void resumeExplorePreview() => _performResumeExplorePreview();
}

extension ExploreControllerPublicPart on ExploreController {
  void suspendExplorePreview({int focusIndex = -1}) =>
      _ExploreControllerSupportX(this)
          .suspendExplorePreview(focusIndex: focusIndex);

  void resumeExplorePreview() =>
      _ExploreControllerSupportX(this).resumeExplorePreview();

  void goToPage(int index) => _handleGoToPage(index);
}
