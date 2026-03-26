part of 'post_content_base.dart';

extension PostContentBaseVisibilityPart<T extends PostContentBase>
    on PostContentBaseState<T> {
  void reportMediaVisibility(double visibleFraction) {
    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex >= 0) {
      agendaController.onPostVisibilityChanged(modelIndex, visibleFraction);
    }

    final surfaceTag = widget.instanceTag ?? '';
    if (visibleFraction < 0.55) return;

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

    final socialProfileController = maybeFindSocialProfileController();
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

    if (surfaceTag.startsWith('archives_')) {
      final archiveController = maybeFindArchiveController();
      if (archiveController == null) return;
      final archiveIndex = archiveController.list
          .indexWhere((p) => p.docID == widget.model.docID);
      if (archiveIndex >= 0) {
        archiveController.currentVisibleIndex.value = archiveIndex;
        archiveController.capturePendingCenteredEntry(
          preferredIndex: archiveIndex,
        );
        if (visibleFraction >= 0.72) {
          archiveController.centeredIndex.value = archiveIndex;
          archiveController.lastCenteredIndex = archiveIndex;
        }
      }
    }

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

    if (surfaceTag.startsWith('top_tag_')) {
      final topTagsController = maybeFindTopTagsController();
      if (topTagsController == null) return;
      final topTagsIndex = topTagsController.agendaList
          .indexWhere((p) => p.docID == widget.model.docID);
      if (topTagsIndex >= 0) {
        topTagsController.currentVisibleIndex.value = topTagsIndex;
        topTagsController.capturePendingCenteredEntry(
          preferredIndex: topTagsIndex,
        );
        if (visibleFraction >= 0.72) {
          topTagsController.centeredIndex.value = topTagsIndex;
          topTagsController.lastCenteredIndex = topTagsIndex;
        }
      }
    }

    if (surfaceTag.startsWith('tag_post_')) {
      final tagPostsController = maybeFindTagPostsController();
      if (tagPostsController == null) return;
      final tagPostIndex = tagPostsController.list
          .indexWhere((p) => p.docID == widget.model.docID);
      if (tagPostIndex >= 0) {
        tagPostsController.currentVisibleIndex.value = tagPostIndex;
        tagPostsController.capturePendingCenteredEntry(
          preferredIndex: tagPostIndex,
        );
        if (visibleFraction >= 0.72) {
          tagPostsController.centeredIndex.value = tagPostIndex;
          tagPostsController.lastCenteredIndex = tagPostIndex;
        }
      }
    }

    if (surfaceTag.startsWith('flood_')) {
      final floodController = maybeFindFloodListingController();
      if (floodController == null) return;
      final floodIndex = floodController.floods
          .indexWhere((p) => p.docID == widget.model.docID);
      if (floodIndex >= 0) {
        floodController.currentVisibleIndex.value = floodIndex;
        floodController.capturePendingCenteredEntry(preferredIndex: floodIndex);
        if (visibleFraction >= 0.72) {
          floodController.centeredIndex.value = floodIndex;
          floodController.lastCenteredIndex = floodIndex;
        }
      }
    }

    final exploreController = maybeFindExploreController();
    if (surfaceTag.startsWith('explore_series_') && exploreController != null) {
      final exploreIndex = exploreController.exploreFloods
          .indexWhere((p) => p.docID == widget.model.docID);
      if (exploreIndex >= 0) {
        exploreController.floodsVisibleIndex.value = exploreIndex;
        exploreController.capturePendingFloodEntry(
          preferredIndex: exploreIndex,
        );
        if (visibleFraction >= 0.72) {
          exploreController.lastFloodVisibleIndex = exploreIndex;
        }
      }
    }
  }

  bool _currentIsAudible() {
    if (isStandalonePostInstance) return true;
    return !agendaController.isMuted.value;
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
