part of 'profile_view.dart';

extension _ProfileViewNavigationPart on _ProfileViewState {
  void _openAboutProfile() {
    _suspendProfileFeedForRoute();
    Get.to(() => AboutProfile(userID: _myUserId))?.then((_) {
      _resumeProfileFeedAfterRoute();
    });
  }

  void _openQrCode() {
    _suspendProfileFeedForRoute();
    Get.to(() => MyQRCode())?.then((_) {
      _resumeProfileFeedAfterRoute();
    });
  }

  void _openChatListing() {
    _suspendProfileFeedForRoute();
    Get.to(() => ChatListing())?.then((_) {
      _resumeProfileFeedAfterRoute();
    });
  }

  void _openSettings() {
    _suspendProfileFeedForRoute();
    Get.to(() => SettingsView())?.then((_) {
      _resumeProfileFeedAfterRoute();
      _refreshUserState();
    });
  }

  void _handleProfileImageTap() {
    final myUserId = _myUserId;

    if (_hasMyStories) {
      try {
        final myStoryUser = storyOwnerUsers.firstWhereOrNull(
          (user) => user.userID == myUserId && user.stories.isNotEmpty,
        );

        if (myStoryUser != null && myStoryUser.stories.isNotEmpty) {
          _suspendProfileFeedForRoute();
          Get.to(() => StoryViewer(
                startedUser: myStoryUser,
                storyOwnerUsers: [myStoryUser],
              ))?.then((_) {
            _resumeProfileFeedAfterRoute();
          });
          return;
        }
      } catch (_) {}
    }

    _openStoryMakerAndRefresh();
  }

  void _openStoryMakerAndRefresh() {
    _suspendProfileFeedForRoute();
    Get.to(() => StoryMaker())?.then((_) {
      _resumeProfileFeedAfterRoute();
      _refreshUserState();
    });
  }

  void _openEditProfile() {
    _suspendProfileFeedForRoute();
    Get.to(() => EditProfile())?.then((_) {
      _resumeProfileFeedAfterRoute();
      _refreshUserState();
    });
  }

  void _openMyStatistics() {
    _suspendProfileFeedForRoute();
    Get.to(() => MyStatisticView())?.then((_) {
      _resumeProfileFeedAfterRoute();
    });
  }
}
