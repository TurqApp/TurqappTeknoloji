part of 'post_content_base.dart';

extension PostContentBaseVisibilityPart<T extends PostContentBase>
    on PostContentBaseState<T> {
  void reportMediaVisibility(double visibleFraction) {
    final surfaceTag = widget.instanceTag ?? '';
    if (surfaceTag.startsWith('flood_')) {
      final floodController = maybeFindFloodListingController();
      if (floodController == null) return;
      final floodIndex = floodController.floods
          .indexWhere((p) => p.docID == widget.model.docID);
      if (floodIndex >= 0) {
        floodController.onPostVisibilityChanged(floodIndex, visibleFraction);
      }
      return;
    }

    if (surfaceTag.startsWith('explore_series_')) {
      final exploreController = maybeFindExploreController();
      if (exploreController == null) return;
      final exploreIndex = exploreController.exploreFloods
          .indexWhere((p) => p.docID == widget.model.docID);
      if (exploreIndex >= 0) {
        exploreController.onExploreFloodVisibilityChanged(
          exploreIndex,
          visibleFraction,
        );
      }
      return;
    }

    if (surfaceTag.startsWith('archives_')) {
      final archiveController = maybeFindArchiveController();
      if (archiveController == null) return;
      final archiveIndex = archiveController.list
          .indexWhere((p) => p.docID == widget.model.docID);
      if (archiveIndex >= 0) {
        archiveController.onPostVisibilityChanged(
          archiveIndex,
          visibleFraction,
        );
      }
      return;
    }

    if (surfaceTag.startsWith('top_tag_')) {
      final topTagsController = maybeFindTopTagsController();
      if (topTagsController == null) return;
      final topTagsIndex = topTagsController.agendaList
          .indexWhere((p) => p.docID == widget.model.docID);
      if (topTagsIndex >= 0) {
        topTagsController.onPostVisibilityChanged(
          topTagsIndex,
          visibleFraction,
        );
      }
      return;
    }

    if (surfaceTag.startsWith('tag_post_')) {
      final tagPostsController = maybeFindTagPostsController();
      if (tagPostsController == null) return;
      final tagPostIndex = tagPostsController.list
          .indexWhere((p) => p.docID == widget.model.docID);
      if (tagPostIndex >= 0) {
        tagPostsController.onPostVisibilityChanged(
          tagPostIndex,
          visibleFraction,
        );
      }
      return;
    }

    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex >= 0) {
      agendaController.onPostVisibilityChanged(modelIndex, visibleFraction);
    }

    final profileController = ProfileController.maybeFind();
    if (surfaceTag.startsWith('profile_') && profileController != null) {
      final profileIndex = profileController.indexOfMergedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (profileIndex >= 0) {
        profileController.onPostVisibilityChanged(
          profileIndex,
          visibleFraction,
        );
      }
    }

    final socialProfileController = _resolveSocialProfileController();
    if (surfaceTag.startsWith('social_') && socialProfileController != null) {
      final socialIndex = socialProfileController.indexOfCombinedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (socialIndex >= 0) {
        socialProfileController.onPostVisibilityChanged(
          socialIndex,
          visibleFraction,
        );
      }
    }

    if (visibleFraction < 0.55) return;

    if (surfaceTag.startsWith('liked_post_')) {
      final likedController = maybeFindLikedPostControllers();
      if (likedController == null) return;
      final likedIndex =
          likedController.all.indexWhere((p) => p.docID == widget.model.docID);
      if (likedIndex >= 0) {
        likedController.currentVisibleIndex.value = likedIndex;
        likedController.capturePendingCenteredEntry(preferredIndex: likedIndex);
        if (visibleFraction >= 0.72) {
          likedController.centeredIndex.value = likedIndex;
          likedController.lastCenteredIndex = likedIndex;
        }
      }
    }
  }

  bool _currentIsAudible() {
    return _resolvedPlaybackVolume() > 0.0;
  }

  void _syncRuntimeHints({
    bool? isAudible,
    bool? hasStableFocus,
  }) {
    VideoTelemetryService.instance.updateRuntimeHints(
      widget.model.docID,
      isAudible: isAudible,
      hasStableFocus: hasStableFocus,
    );
  }

  void _trackPlaybackIntent() {
    if (_playbackIntentTracked) return;
    final playbackKpi = maybeFindPlaybackKpiService();
    if (playbackKpi == null) return;
    _playbackIntentTracked = true;
    playbackKpi.track(
      PlaybackKpiEventType.playbackIntent,
      {
        'surface': isStandalonePostInstance ? 'single_post' : 'feed_post',
        'videoId': widget.model.docID,
        'audible': _currentIsAudible(),
        'stableFocus': true,
      },
    );
  }
}
