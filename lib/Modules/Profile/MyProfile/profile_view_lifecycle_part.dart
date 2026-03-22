part of 'profile_view.dart';

extension _ProfileViewLifecyclePart on _ProfileViewState {
  void _initializeProfileView() {
    final existingController = ProfileController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ProfileController.ensure();
      _ownsController = true;
    }
    final existingSocialMediaController = SocialMediaController.maybeFind();
    if (existingSocialMediaController != null) {
      socialMediaController = existingSocialMediaController;
    } else {
      socialMediaController = SocialMediaController.ensure();
      _ownsSocialMediaController = true;
    }
    try {
      VideoStateManager.instance.pauseAllVideos(force: true);
    } catch (_) {}
    try {
      AudioFocusCoordinator.instance.pauseAllAudioPlayers();
    } catch (_) {}
    try {
      AgendaController.ensure().isMuted.value = false;
    } catch (_) {}
    _scheduleOnScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_refreshProfileSurfaceMeta(force: false));
    });
    _marketUserWorker = ever(userService.currentUserRx, (_) {
      unawaited(_refreshProfileSurfaceMeta(force: false));
    });

    final highlightsController = _ensureProfileHighlightsController();
    if (highlightsController != null) {
      unawaited(highlightsController.loadHighlights());
    }
  }

  void _disposeProfileView() {
    _marketUserWorker?.dispose();
    if (_ownsHighlightsController) {
      final uid = _myUserId;
      final tag = uid.isEmpty ? '' : 'highlights_$uid';
      if (tag.isNotEmpty &&
          StoryHighlightsController.maybeFind(tag: tag) != null) {
        Get.delete<StoryHighlightsController>(tag: tag, force: true);
      }
    }
    if (_ownsSocialMediaController &&
        identical(
          SocialMediaController.maybeFind(),
          socialMediaController,
        )) {
      Get.delete<SocialMediaController>(force: true);
    }
    if (_ownsController &&
        identical(ProfileController.maybeFind(), controller)) {
      Get.delete<ProfileController>(force: true);
    }
  }

  void _refreshUserState() {
    userService.forceRefresh();
    StoryRowController.refreshStoriesGlobally();
    unawaited(_loadMarketItems(force: true));
  }

  void _showProfileImagePreview() {
    controller.capturePendingCenteredEntry();
    controller.lastCenteredIndex = controller.currentVisibleIndex.value >= 0
        ? controller.currentVisibleIndex.value
        : controller.lastCenteredIndex;
    controller.showPfImage.value = true;
    controller.centeredIndex.value = -1;
  }

  void _hideProfileImagePreview() {
    controller.showPfImage.value = false;
    controller.resumeCenteredPost();
  }

  void _suspendProfileFeedForRoute() {
    controller.capturePendingCenteredEntry();
    controller.lastCenteredIndex = controller.currentVisibleIndex.value >= 0
        ? controller.currentVisibleIndex.value
        : controller.lastCenteredIndex;
    controller.pausetheall.value = true;
    controller.centeredIndex.value = -1;
  }

  void _resumeProfileFeedAfterRoute() {
    controller.resumeCenteredPost();
  }

  Future<void> _loadMarketItems({bool force = false}) async {
    final uid = _myUserId.trim();
    if (uid.isEmpty) return;
    if (_marketLoading && !force) return;
    _updateViewState(() {
      _marketLoading = true;
    });
    try {
      final items = await _marketRepository.fetchByOwner(
        uid,
        preferCache: !force,
        forceRefresh: force,
      );
      _updateViewState(() {
        _marketItems = items
            .where((item) => item.status != 'archived')
            .toList(growable: false);
      });
    } catch (_) {
      _updateViewState(() {
        _marketItems = const <MarketItemModel>[];
      });
    } finally {
      _updateViewState(() {
        _marketLoading = false;
      });
    }
  }

  void _onScroll() {
    _scrollProbeScheduled = false;
    if (!mounted) return;
    final activeScrollController = controller.currentScrollController;
    if (!activeScrollController.hasClients) return;

    final position = activeScrollController.position;
    if (position.pixels >= position.maxScrollExtent - 300) {
      controller.fetchPosts();
      controller.fetchPhotos();
      controller.fetchVideos();
    }
    if (controller.postSelection.value == 0) {
      return;
    }
    final merged = controller.mergedPosts;
    if (merged.isEmpty) return;

    if (position.pixels <= 0) {
      controller.currentVisibleIndex.value = 0;
      if (controller.centeredIndex.value != 0) {
        _updateViewState(() {
          controller.centeredIndex.value = 0;
          controller.lastCenteredIndex = 0;
        });
      }
      return;
    }

    final safeLastIndex = merged.length - 1;
    if (controller.currentVisibleIndex.value > safeLastIndex) {
      controller.currentVisibleIndex.value = safeLastIndex;
    }
    if (controller.centeredIndex.value > safeLastIndex) {
      _updateViewState(() {
        controller.centeredIndex.value = safeLastIndex;
        controller.lastCenteredIndex = safeLastIndex;
      });
    }
  }

  void _scheduleOnScroll() {
    if (_scrollProbeScheduled || !mounted) return;
    _scrollProbeScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _scrollProbeScheduled = false;
        return;
      }
      _onScroll();
    });
  }
}
