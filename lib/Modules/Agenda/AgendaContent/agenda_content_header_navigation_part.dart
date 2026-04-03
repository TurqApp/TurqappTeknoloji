part of 'agenda_content.dart';

extension AgendaContentHeaderNavigationPart on _AgendaContentState {
  List<StoryUserModel> _storyUsersSnapshot() {
    final rowController = maybeFindStoryRowController();
    if (rowController == null) return const [];
    return rowController.users.toList(growable: false);
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

  void _suspendAgendaFeedForRoute() {
    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex >= 0) {
      agendaController.lastCenteredIndex = modelIndex;
    }
    agendaController.centeredIndex.value = -1;
    _suspendEmbeddedFeedContextsForRoute();
    videoController?.pause();
  }

  void _restoreAgendaFeedCenter() {
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

  bool _hasStoryAvatar() {
    final storyUser = _resolveStoryUser();
    return storyUser != null && storyUser.stories.isNotEmpty;
  }

  void _openAvatarStoryOrProfile() {
    final storyUser = _resolveStoryUser();
    if (widget.model.userID == _currentUid &&
        (storyUser == null || storyUser.stories.isEmpty)) {
      return;
    }
    final modelIndex = agendaController.agendaList
        .indexWhere((p) => p.docID == widget.model.docID);
    if (modelIndex >= 0) {
      agendaController.lastCenteredIndex = modelIndex;
    }
    agendaController.centeredIndex.value = -1;
    if (storyUser != null && storyUser.stories.isNotEmpty) {
      videoController?.pause();
      final users = _storyUsersSnapshot();
      Get.to(() => StoryViewer(
            startedUser: storyUser,
            storyOwnerUsers: users,
          ))?.then((_) {
        _restoreAgendaFeedCenter();
      });
      return;
    }

    videoController?.pause();
    final route = Get.to(() => SocialProfile(userID: widget.model.userID));
    route?.then((_) {
      _restoreAgendaFeedCenter();
    });
  }

  Widget _buildStoryAwareAvatar({
    required String userId,
    required String imageUrl,
    required double radius,
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
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
          colors: ringColors,
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
        ),
      ),
    );
  }
}
