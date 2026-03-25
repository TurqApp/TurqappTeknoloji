part of 'explore_controller.dart';

extension _ExploreControllerSupportX on ExploreController {
  UserProfileCacheService get _userCache => UserProfileCacheService.ensure();

  UserSubcollectionRepository get _subcollectionRepository =>
      UserSubcollectionRepository.ensure();

  TopTagsRepository get _topTagsRepository => TopTagsRepository.ensure();

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

  void capturePendingFloodEntry({int? preferredIndex, PostsModel? model}) =>
      _performCapturePendingFloodEntry(
        preferredIndex: preferredIndex,
        model: model,
      );

  void suspendExplorePreview({int focusIndex = -1}) =>
      _performSuspendExplorePreview(focusIndex: focusIndex);

  void resumeExplorePreview() => _performResumeExplorePreview();
}
