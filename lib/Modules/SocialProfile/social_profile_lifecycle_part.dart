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
        SocialProfileController.maybeFind(tag: widget.userID);
    if (existingController != null) {
      controller = existingController;
    } else {
      controller = SocialProfileController.ensure(
        userID: widget.userID,
        tag: widget.userID,
      );
      _ownsController = true;
    }
    final highlightsTag = 'highlights_${widget.userID}';
    if (StoryHighlightsController.maybeFind(tag: highlightsTag) == null) {
      StoryHighlightsController.ensure(
        userId: widget.userID,
        tag: highlightsTag,
      );
      _ownsHighlightsController = true;
    }
    for (final selection in const <int>[0, 1, 2, 3, 4, 5]) {
      _scrollControllerForSelection(selection);
    }
    _scheduleOnScroll();
  }

  void _disposeSocialProfile() {
    for (final scrollController in _scrollControllers.values) {
      scrollController.dispose();
    }
    if (_ownsHighlightsController) {
      final highlightsTag = 'highlights_${widget.userID}';
      if (StoryHighlightsController.maybeFind(tag: highlightsTag) != null) {
        Get.delete<StoryHighlightsController>(
          tag: highlightsTag,
          force: true,
        );
      }
    }
    if (_ownsController &&
        identical(
          SocialProfileController.maybeFind(tag: widget.userID),
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

    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      controller.getPosts(initial: false);
      controller.getPhotos(initial: false);
    }

    final activeFeedLength = controller.postSelection.value == 0
        ? controller.combinedFeedEntries.length
        : controller.allPosts.length;
    if (activeFeedLength == 0) return;

    if (scrollController.offset <= 0) {
      if (controller.centeredIndex.value != 0) {
        _updateSocialProfileState(() {
          controller.centeredIndex.value = 0;
          controller.lastCenteredIndex = 0;
        });
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
    _setCenteredIndex(-1);
  }

  void _resumeCenteredPostAfterRoute() {
    _updateSocialProfileState(controller.resumeCenteredPost);
  }

  void _showProfileImagePreview() {
    if (!mounted || controller.avatarUrl.value.isEmpty) return;
    _updateSocialProfileState(() {
      controller.capturePendingCenteredEntry();
      controller.lastCenteredIndex = controller.currentVisibleIndex.value >= 0
          ? controller.currentVisibleIndex.value
          : controller.lastCenteredIndex;
      controller.showPfImage.value = true;
      controller.centeredIndex.value = -1;
    });
  }

  void _hideProfileImagePreview() {
    _updateSocialProfileState(() {
      controller.showPfImage.value = false;
      controller.resumeCenteredPost();
    });
  }
}
