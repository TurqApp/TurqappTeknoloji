part of 'social_profile.dart';

extension _SocialProfileLifecyclePart on _SocialProfileState {
  void _initializeSocialProfile() {
    try {
      VideoStateManager.instance.pauseAllVideos(force: true);
    } catch (_) {}
    try {
      AudioFocusCoordinator.instance.pauseAllAudioPlayers();
    } catch (_) {}
    final existingChatListing = ChatListingController.maybeFind();
    if (existingChatListing != null) {
      chatListingController = existingChatListing;
    } else {
      chatListingController = ChatListingController.ensure();
      _ownsChatListingController = true;
    }
    final existingController =
        maybeFindSocialProfileController(tag: widget.userID);
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = ensureSocialProfileController(
        userID: widget.userID,
        tag: widget.userID,
      );
      _ownsController = true;
    }
    final highlightsTag = 'highlights_${widget.userID}';
    if (maybeFindStoryHighlightsController(tag: highlightsTag) == null) {
      ensureStoryHighlightsController(
          userId: widget.userID, tag: highlightsTag);
      _ownsHighlightsController = true;
    }
    for (final selection in const <int>[0, 1, 2, 3, 4, 5]) {
      _scrollControllerForSelection(selection);
    }
    _scheduleOnScroll();
  }

  void _disposeSocialProfile() {
    _scrollSettleDebounce?.cancel();
    _linksHighlightsScrollController.dispose();
    for (final scrollController in _scrollControllers.values) {
      scrollController.dispose();
    }
    if (_ownsHighlightsController) {
      final highlightsTag = 'highlights_${widget.userID}';
      if (maybeFindStoryHighlightsController(tag: highlightsTag) != null) {
        Get.delete<StoryHighlightsController>(
          tag: highlightsTag,
          force: true,
        );
      }
    }
    if (_ownsController &&
        identical(
          maybeFindSocialProfileController(tag: widget.userID),
          controller,
        )) {
      Get.delete<SocialProfileController>(tag: widget.userID, force: true);
    }
    if (_ownsChatListingController &&
        identical(ChatListingController.maybeFind(), chatListingController)) {
      Get.delete<ChatListingController>(force: true);
    }
  }

  ScrollController _scrollControllerForSelection(int selection) {
    return _scrollControllers.putIfAbsent(
      selection,
      () => _buildTrackedScrollController(selection),
    );
  }

  ScrollController _buildTrackedScrollController(int selection) {
    final scrollController = ScrollController();
    scrollController.addListener(() {
      if (controller.postSelection.value != selection) return;
      if (controller.showScrollToTop.value != (scrollController.offset > 500)) {
        controller.showScrollToTop.value = scrollController.offset > 500;
      }
    });
    return scrollController;
  }

  void _onScroll() {
    _scrollProbeScheduled = false;
    final scrollController = _currentScrollController;
    if (!scrollController.hasClients) return;

    final shouldShowScrollToTop = scrollController.offset > 500;
    if (controller.showScrollToTop.value != shouldShowScrollToTop) {
      controller.showScrollToTop.value = shouldShowScrollToTop;
    }

    final activeFeedLength = controller.postSelection.value == 0
        ? controller.combinedFeedEntries.length
        : controller.allPosts.length;
    final anchorIndex = controller.currentVisibleIndex.value >= 0
        ? controller.currentVisibleIndex.value
        : controller.centeredIndex.value;
    final shouldFetchMoreFeedItems = controller.postSelection.value == 0 &&
        activeFeedLength > 0 &&
        anchorIndex >= 0 &&
        activeFeedLength - (anchorIndex + 1) <=
            controller.feedLoadTriggerRemaining;

    if (shouldFetchMoreFeedItems) {
      controller.getPosts(initial: false);
    } else if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      controller.getPosts(initial: false);
      controller.getPhotos(initial: false);
    }

    if (activeFeedLength == 0) return;

    if (scrollController.offset <= 0) {
      controller.currentVisibleIndex.value = 0;
      if (controller.centeredIndex.value != 0) {
        _updateSocialProfileState(() {
          controller.centeredIndex.value = 0;
          controller.lastCenteredIndex = 0;
        });
      } else {
        controller.lastCenteredIndex = 0;
      }
      if (controller.postSelection.value == 0) {
        _scrollSettleDebounce?.cancel();
        _scrollSettleDebounce = Timer(
          FeedPlaybackSelectionPolicy.scrollSettleReassertDuration,
          () {
            if (!mounted || controller.postSelection.value != 0) return;
            final centered = controller.centeredIndex.value;
            if (centered >= 0 &&
                centered < controller.combinedFeedEntries.length) {
              controller.ensureCenteredPlaybackForCurrentSelection();
            } else {
              controller.resumeCenteredPost();
            }
          },
        );
      }
      return;
    }

    final safeLastIndex = activeFeedLength - 1;
    if (controller.centeredIndex.value > safeLastIndex) {
      _updateSocialProfileState(() {
        controller.centeredIndex.value = safeLastIndex;
        controller.lastCenteredIndex = safeLastIndex;
      });
    }

    if (controller.postSelection.value == 0) {
      _scrollSettleDebounce?.cancel();
      _scrollSettleDebounce = Timer(
        FeedPlaybackSelectionPolicy.scrollSettleReassertDuration,
        () {
          if (!mounted || controller.postSelection.value != 0) return;
          final centered = controller.centeredIndex.value;
          if (centered >= 0 &&
              centered < controller.combinedFeedEntries.length) {
            controller.ensureCenteredPlaybackForCurrentSelection();
          } else {
            controller.resumeCenteredPost();
          }
        },
      );
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

  Future<void> _changePostSelection(int index) async {
    await controller.setPostSelection(index);
    final scrollController = _scrollControllerForSelection(index);
    if (!mounted) return;
    controller.showScrollToTop.value =
        scrollController.hasClients && scrollController.offset > 500;
    _scheduleOnScroll();
  }

  void _setCenteredIndex(int value) {
    _updateSocialProfileState(() {
      controller.centeredIndex.value = value;
      if (value >= 0) {
        controller.lastCenteredIndex = value;
      }
    });
  }

  void _suspendCenteredPostForRoute([
    PostsModel? model,
    bool isReshare = false,
  ]) {
    if (!mounted) return;
    if (model != null) {
      controller.capturePendingCenteredEntry(
        model: model,
        isReshare: isReshare,
      );
      final modelIndex = controller.postSelection.value == 0
          ? controller.indexOfCombinedEntry(
              docId: model.docID,
              isReshare: isReshare,
            )
          : controller.allPosts.indexWhere((post) => post.docID == model.docID);
      if (modelIndex >= 0) {
        controller.lastCenteredIndex = modelIndex;
      }
    } else {
      controller.capturePendingCenteredEntry();
    }
    _updateSocialProfileState(() {
      if (controller.surfacePlaybackSuspended.value &&
          controller.centeredIndex.value == -1) {
        return;
      }
      controller.surfacePlaybackSuspended.value = true;
      controller.centeredIndex.value = -1;
    });
    try {
      VideoStateManager.instance.pauseAllVideos(force: true);
    } catch (_) {}
    try {
      AudioFocusCoordinator.instance.pauseAllAudioPlayers();
    } catch (_) {}
  }

  void _resumeCenteredPostAfterRoute() {
    _updateSocialProfileState(() {
      controller.surfacePlaybackSuspended.value = false;
      controller.resumeCenteredPost();
    });
  }

  void _showProfileImagePreview() {
    if (!mounted || controller.avatarUrl.value.isEmpty) return;
    _updateSocialProfileState(() {
      controller.capturePendingCenteredEntry();
      controller.lastCenteredIndex = controller.currentVisibleIndex.value >= 0
          ? controller.currentVisibleIndex.value
          : controller.lastCenteredIndex;
      controller.surfacePlaybackSuspended.value = true;
      controller.showPfImage.value = true;
      controller.centeredIndex.value = -1;
    });
  }

  void _hideProfileImagePreview() {
    _updateSocialProfileState(() {
      controller.surfacePlaybackSuspended.value = false;
      controller.showPfImage.value = false;
      controller.resumeCenteredPost();
    });
  }
}
