// ignore_for_file: invalid_use_of_protected_member

part of 'classic_content.dart';

extension ClassicContentHelpersPart on _ClassicContentState {
  void _setCaptionExpanded(bool value) {
    setState(() {
      _isCaptionExpanded = value;
    });
  }

  void _setQuoteExpanded(bool value) {
    setState(() {
      _isQuoteExpanded = value;
    });
  }

  void _setFullscreen(bool value) {
    setState(() {
      _isFullscreen = value;
    });
  }

  void _setCurrentPage(int value) {
    if (!mounted || _currentPage == value) return;
    setState(() => _currentPage = value);
  }

  Future<void> _subscribeToIzBirak() async {
    AppSnackbar(
      'İz Bırak',
      'Yayın tarihinde bildirim alacaksınız.',
    );
    final ok =
        await IzBirakSubscriptionService.ensure().subscribe(widget.model.docID);
    if (!ok) {
      AppSnackbar(
        'İz Bırak',
        'Bildirim kaydı oluşturulamadı.',
        backgroundColor: Colors.red.shade700.withValues(alpha: 0.92),
      );
    }
  }

  Widget _buildIzBirakBlurOverlay() {
    if (!_shouldBlurIzBirakPost) return const SizedBox.shrink();
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.black.withValues(alpha: 0.16),
          ),
        ),
      ),
    );
  }

  Widget _buildIzBirakBottomBar() {
    if (!_isIzBirakPost) return const SizedBox.shrink();
    final text = 'Yayın Tarihi : ${formatIzBirakLong(_izBirakPublishDate)}';
    final subscriptionService = IzBirakSubscriptionService.ensure();
    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Obx(() {
                final subscribed =
                    subscriptionService.isSubscribed(widget.model.docID);
                return SizedBox(
                  width: 40,
                  height: 40,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 40),
                    borderRadius: BorderRadius.circular(20),
                    onPressed: subscribed ? null : _subscribeToIzBirak,
                    child: Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            subscribed ? const Color(0xFF1F8F46) : Colors.green,
                      ),
                      child: Icon(
                        subscribed
                            ? CupertinoIcons.check_mark
                            : CupertinoIcons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  ShortController get shortsController => ensureShortController();

  Widget _buildClassicAvatar({
    required String userId,
    required String imageUrl,
    double radius = 16.5,
  }) {
    final hasStory = _hasStoryAvatar();
    final ringColors = hasStory
        ? const [
            Color(0xFFB7F3D0),
            Color(0xFF5AD39A),
            Color(0xFF20B26B),
            Color(0xFF12824D),
          ]
        : const [
            Color(0xFFB7D8FF),
            Color(0xFF6EB6FF),
            Color(0xFF2C8DFF),
            Color(0xFF0E5BFF),
          ];

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: ringColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: CachedUserAvatar(
          userId: userId,
          imageUrl: imageUrl,
          radius: radius,
          debugSurface: 'feed_card_avatar',
          debugKey: widget.model.docID,
        ),
      ),
    );
  }

  StoryUserModel? _resolveStoryUser() {
    final rowController = maybeFindStoryRowController();
    if (rowController == null) return null;
    final users = rowController.users;
    for (final user in users) {
      if (user.userID == widget.model.userID) {
        return user;
      }
    }
    return null;
  }

  bool _hasStoryAvatar() {
    final storyUser = _resolveStoryUser();
    return storyUser != null && storyUser.stories.isNotEmpty;
  }

  void _suspendEmbeddedFeedContextsForRoute() {
    final floodController = maybeFindFloodListingController();
    if (floodController != null) {
      final floodIndex = floodController.floods
          .indexWhere((p) => p.docID == widget.model.docID);
      if (floodIndex >= 0) {
        floodController.capturePendingCenteredEntry(model: widget.model);
        floodController.lastCenteredIndex = floodIndex;
        floodController.centeredIndex.value = -1;
      }
    }

    final profileController = ProfileController.maybeFind();
    if (profileController != null) {
      final profileIndex = profileController.indexOfMergedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (profileIndex >= 0) {
        profileController.lastCenteredIndex = profileIndex;
        profileController.currentVisibleIndex.value = -1;
        profileController.centeredIndex.value = -1;
        profileController.pausetheall.value = true;
      }
    }

    final socialProfileController = maybeFindSocialProfileController();
    if (socialProfileController != null) {
      final socialIndex = socialProfileController.indexOfCombinedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (socialIndex >= 0) {
        socialProfileController.lastCenteredIndex = socialIndex;
        socialProfileController.currentVisibleIndex.value = -1;
        socialProfileController.centeredIndex.value = -1;
      }
    }

    final archiveController = maybeFindArchiveController();
    if (archiveController != null) {
      final archiveIndex = archiveController.list
          .indexWhere((p) => p.docID == widget.model.docID);
      if (archiveIndex >= 0) {
        archiveController.capturePendingCenteredEntry(model: widget.model);
        archiveController.lastCenteredIndex = archiveIndex;
        archiveController.centeredIndex.value = -1;
      }
    }

    final likedController = maybeFindLikedPostControllers();
    if (likedController != null) {
      final likedIndex =
          likedController.all.indexWhere((p) => p.docID == widget.model.docID);
      if (likedIndex >= 0) {
        likedController.capturePendingCenteredEntry(model: widget.model);
        likedController.lastCenteredIndex = likedIndex;
        likedController.currentVisibleIndex.value = -1;
        likedController.centeredIndex.value = -1;
      }
    }

    final topTagsController = maybeFindTopTagsController();
    if (topTagsController != null) {
      final topTagsIndex = topTagsController.agendaList
          .indexWhere((p) => p.docID == widget.model.docID);
      if (topTagsIndex >= 0) {
        topTagsController.capturePendingCenteredEntry(model: widget.model);
        topTagsController.lastCenteredIndex = topTagsIndex;
        topTagsController.currentVisibleIndex.value = -1;
        topTagsController.centeredIndex.value = -1;
      }
    }

    final tagPostsController = maybeFindTagPostsController();
    if (tagPostsController != null) {
      final tagPostIndex = tagPostsController.list
          .indexWhere((p) => p.docID == widget.model.docID);
      if (tagPostIndex >= 0) {
        tagPostsController.capturePendingCenteredEntry(model: widget.model);
        tagPostsController.lastCenteredIndex = tagPostIndex;
        tagPostsController.currentVisibleIndex.value = -1;
        tagPostsController.centeredIndex.value = -1;
      }
    }

    final exploreController = maybeFindExploreController();
    if (exploreController != null) {
      final exploreIndex = exploreController.exploreFloods
          .indexWhere((p) => p.docID == widget.model.docID);
      if (exploreIndex >= 0) {
        exploreController.capturePendingFloodEntry(model: widget.model);
        exploreController.lastFloodVisibleIndex = exploreIndex;
        exploreController.floodsVisibleIndex.value = -1;
      }
    }
  }

  void _restoreEmbeddedFeedContexts() {
    final floodController = maybeFindFloodListingController();
    if (floodController != null) {
      final floodIndex = floodController.floods
          .indexWhere((p) => p.docID == widget.model.docID);
      if (floodIndex >= 0) {
        floodController.capturePendingCenteredEntry(model: widget.model);
        floodController.centeredIndex.value = floodIndex;
        floodController.currentVisibleIndex.value = floodIndex;
        floodController.lastCenteredIndex = floodIndex;
      }
    }

    final profileController = ProfileController.maybeFind();
    if (profileController != null) {
      final profileIndex = profileController.indexOfMergedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (profileIndex >= 0) {
        profileController.lastCenteredIndex = profileIndex;
        profileController.currentVisibleIndex.value = profileIndex;
        profileController.centeredIndex.value = profileIndex;
        profileController.pausetheall.value = false;
      }
    }

    final socialProfileController = maybeFindSocialProfileController();
    if (socialProfileController != null) {
      final socialIndex = socialProfileController.indexOfCombinedEntry(
        docId: widget.model.docID,
        isReshare: widget.isReshared,
      );
      if (socialIndex >= 0) {
        socialProfileController.lastCenteredIndex = socialIndex;
        socialProfileController.currentVisibleIndex.value = socialIndex;
        socialProfileController.centeredIndex.value = socialIndex;
      }
    }

    final archiveController = maybeFindArchiveController();
    if (archiveController != null) {
      final archiveIndex = archiveController.list
          .indexWhere((p) => p.docID == widget.model.docID);
      if (archiveIndex >= 0) {
        archiveController.capturePendingCenteredEntry(model: widget.model);
        archiveController.lastCenteredIndex = archiveIndex;
        archiveController.currentVisibleIndex.value = archiveIndex;
        archiveController.centeredIndex.value = archiveIndex;
      }
    }

    final likedController = maybeFindLikedPostControllers();
    if (likedController != null) {
      final likedIndex =
          likedController.all.indexWhere((p) => p.docID == widget.model.docID);
      if (likedIndex >= 0) {
        likedController.capturePendingCenteredEntry(model: widget.model);
        likedController.lastCenteredIndex = likedIndex;
        likedController.currentVisibleIndex.value = likedIndex;
        likedController.centeredIndex.value = likedIndex;
      }
    }

    final topTagsController = maybeFindTopTagsController();
    if (topTagsController != null) {
      final topTagsIndex = topTagsController.agendaList
          .indexWhere((p) => p.docID == widget.model.docID);
      if (topTagsIndex >= 0) {
        topTagsController.capturePendingCenteredEntry(model: widget.model);
        topTagsController.lastCenteredIndex = topTagsIndex;
        topTagsController.currentVisibleIndex.value = topTagsIndex;
        topTagsController.centeredIndex.value = topTagsIndex;
      }
    }

    final tagPostsController = maybeFindTagPostsController();
    if (tagPostsController != null) {
      final tagPostIndex = tagPostsController.list
          .indexWhere((p) => p.docID == widget.model.docID);
      if (tagPostIndex >= 0) {
        tagPostsController.capturePendingCenteredEntry(model: widget.model);
        tagPostsController.lastCenteredIndex = tagPostIndex;
        tagPostsController.currentVisibleIndex.value = tagPostIndex;
        tagPostsController.centeredIndex.value = tagPostIndex;
      }
    }

    final exploreController = maybeFindExploreController();
    if (exploreController != null) {
      final exploreIndex = exploreController.exploreFloods
          .indexWhere((p) => p.docID == widget.model.docID);
      if (exploreIndex >= 0) {
        exploreController.capturePendingFloodEntry(model: widget.model);
        exploreController.floodsVisibleIndex.value = exploreIndex;
        exploreController.lastFloodVisibleIndex = exploreIndex;
      }
    }
  }

  void _restoreClassicFeedCenter() {
    final last = agendaController.lastCenteredIndex;
    int target = -1;
    if (last != null &&
        last >= 0 &&
        last < agendaController.agendaList.length) {
      target = last;
    } else {
      final modelIndex = agendaController.agendaList
          .indexWhere((p) => p.docID == widget.model.docID);
      if (modelIndex >= 0) {
        target = modelIndex;
      } else if (agendaController.agendaList.isNotEmpty) {
        target = 0;
      }
    }
    if (target >= 0 && target < agendaController.agendaList.length) {
      agendaController.centeredIndex.value = target;
      agendaController.lastCenteredIndex = target;
    }
    _restoreEmbeddedFeedContexts();
  }

  void _openAvatarStoryOrProfile() {
    final storyUser = _resolveStoryUser();
    if (widget.model.userID == _currentUid &&
        (storyUser == null || storyUser.stories.isEmpty)) {
      return;
    }
    _suspendClassicFeedForRoute();
    if (storyUser != null && storyUser.stories.isNotEmpty) {
      final users = maybeFindStoryRowController()?.users.toList(
                growable: false,
              ) ??
          const <StoryUserModel>[];
      Get.to(() => StoryViewer(
            startedUser: storyUser,
            storyOwnerUsers: users,
          ))?.then((_) {
        _restoreClassicFeedCenter();
      });
      return;
    }

    final route =
        const ProfileNavigationService().openSocialProfile(widget.model.userID);
    route.then((_) {
      _restoreClassicFeedCenter();
    });
  }

  void _suspendClassicFeedForRoute() {
    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex >= 0) {
      agendaController.lastCenteredIndex = modelIndex;
    }
    agendaController.centeredIndex.value = -1;
    _suspendEmbeddedFeedContextsForRoute();
    videoController?.pause();
  }

  Widget _buildClassicWhiteBadge(double size) {
    return Transform.translate(
      offset: const Offset(0, -1),
      child: Padding(
        padding: const EdgeInsets.only(left: 3),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: Colors.white,
              size: size,
            ),
            Icon(
              CupertinoIcons.check_mark,
              color: Colors.black87,
              size: size * 0.42,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassicOverlayFollowButton({required bool loading}) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(15)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: 28,
          alignment: Alignment.center,
          constraints: const BoxConstraints(minWidth: 72),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            border: Border.all(color: Colors.white),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            child: loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'following.follow'.tr,
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: "MontserratMedium",
                      fontSize: _classicPlatformFontSize(14),
                      height: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassicFollowButtonBlack() {
    return Container(
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: Colors.black),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Text(
          "Takip Et",
          style: TextStyle(
            color: Colors.black,
            fontFamily: "MontserratMedium",
            fontSize: _classicPlatformFontSize(12),
          ),
        ),
      ),
    );
  }

  Widget _buildClassicMediaHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: headerUserInfoWhite(),
    );
  }
}
