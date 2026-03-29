part of 'profile_view.dart';

extension _ProfileViewLifecyclePart on _ProfileViewState {
  bool _isProfileSurfaceActive() {
    final nav = maybeFindNavBarController();
    if (nav == null) {
      final route = Get.currentRoute.trim();
      if (route == '/NavBarView' || route == 'NavBarView') {
        return false;
      }
      return true;
    }
    final settings = maybeFindSettingsController();
    final hasEducation = settings?.educationScreenIsOn.value ?? false;
    final profileIndex = hasEducation ? 4 : 3;
    return nav.selectedIndex.value == profileIndex;
  }

  void _refreshProfileSurfaceMetaIfActive({bool force = false}) {
    if (!_isProfileSurfaceActive()) return;
    unawaited(_refreshProfileSurfaceMeta(force: force));
  }

  void _refreshProfileSupplementalMetaIfActive({bool force = false}) {
    if (!_isProfileSurfaceActive()) return;
    unawaited(_refreshProfileSupplementalMeta(force: force));
  }

  void _initializeProfileView() {
    final existingController = ProfileController.maybeFind();
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ProfileController.ensure();
      _ownsController = true;
    }
    final existingSocialMediaController = maybeFindSocialMediaController();
    if (existingSocialMediaController != null) {
      socialMediaController = existingSocialMediaController;
    } else {
      socialMediaController = ensureSocialMediaController();
      _ownsSocialMediaController = true;
    }
    try {
      VideoStateManager.instance.pauseAllVideos(force: true);
    } catch (_) {}
    try {
      AudioFocusCoordinator.instance.pauseAllAudioPlayers();
    } catch (_) {}
    _scheduleOnScroll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(controller.onPrimarySurfaceVisible());
      _refreshProfileSupplementalMetaIfActive(force: false);
    });
    _marketUserWorker = ever(userService.currentUserRx, (_) {
      _refreshProfileSurfaceMetaIfActive(force: false);
    });
    final nav = maybeFindNavBarController();
    if (nav != null) {
      _profileTabWorker = ever<int>(nav.selectedIndex, (_) {
        _refreshProfileSurfaceMetaIfActive(force: false);
      });
    }
  }

  void _disposeProfileView() {
    _marketUserWorker?.dispose();
    _profileTabWorker?.dispose();
    _scrollSettleDebounce?.cancel();
    _linksHighlightsScrollController.dispose();
    if (_ownsHighlightsController) {
      final uid = _myUserId;
      final tag = uid.isEmpty ? '' : 'highlights_$uid';
      if (tag.isNotEmpty &&
          maybeFindStoryHighlightsController(tag: tag) != null) {
        Get.delete<StoryHighlightsController>(tag: tag, force: true);
      }
    }
    if (_ownsSocialMediaController &&
        identical(
          maybeFindSocialMediaController(),
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
    refreshStoryRowGlobally();
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
      final items = await _loadProfileMarketItems(
        uid,
        force: force,
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

  Future<List<MarketItemModel>> _loadProfileMarketItems(
    String userId, {
    required bool force,
  }) async {
    if (force) {
      final resource = await _marketSnapshotRepository.loadOwner(
        userId: userId,
        forceSync: true,
      );
      return resource.data ?? const <MarketItemModel>[];
    }

    final cached = await _marketSnapshotRepository.loadCachedOwner(
      userId: userId,
    );
    if (cached.hasLocalSnapshot && cached.data != null) {
      return cached.data!;
    }

    final live = await _marketSnapshotRepository.loadOwner(
      userId: userId,
      forceSync: true,
    );
    return live.data ?? const <MarketItemModel>[];
  }

  void _onScroll() {
    _scrollProbeScheduled = false;
    if (!mounted) return;
    final position = controller.currentScrollPosition;
    if (position == null) return;
    if (position.pixels >= position.maxScrollExtent - 300) {
      controller.fetchPosts();
      controller.fetchPhotos();
      controller.fetchVideos();
    }
    if (controller.postSelection.value == 0) {
      _scrollSettleDebounce?.cancel();
      _scrollSettleDebounce = Timer(
        FeedPlaybackSelectionPolicy.scrollSettleReassertDuration,
        () {
          if (!mounted || controller.postSelection.value != 0) return;
          final centered = controller.centeredIndex.value;
          if (centered >= 0 && centered < controller.mergedPosts.length) {
            controller.ensureCenteredPlaybackForCurrentSelection();
          } else {
            controller.resumeCenteredPost();
          }
        },
      );
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
