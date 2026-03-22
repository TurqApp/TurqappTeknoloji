class IntegrationTestKeys {
  static const String screenSplash = 'it-screen-splash';
  static const String screenSignIn = 'it-screen-sign-in';
  static const String navBarRoot = 'it-nav-bar-root';
  static const String navFeed = 'it-nav-feed';
  static const String navExplore = 'it-nav-explore';
  static const String navShort = 'it-nav-short';
  static const String navChat = 'it-nav-chat';
  static const String navEducation = 'it-nav-education';
  static const String navProfile = 'it-nav-profile';

  static const String screenFeed = 'it-screen-feed';
  static const String screenExplore = 'it-screen-explore';
  static const String screenProfile = 'it-screen-profile';
  static const String screenSocialProfile = 'it-screen-social-profile';
  static const String screenShort = 'it-screen-short';
  static const String screenChat = 'it-screen-chat';
  static const String screenChatConversation = 'it-screen-chat-conversation';
  static const String screenEducation = 'it-screen-education';
  static const String screenNotifications = 'it-screen-notifications';
  static const String screenFollowingFollowers =
      'it-screen-following-followers';
  static const String screenSettings = 'it-screen-settings';
  static const String screenEditProfile = 'it-screen-edit-profile';
  static const String screenPostCreator = 'it-screen-post-creator';
  static const String screenComments = 'it-screen-comments';
  static const String screenSinglePost = 'it-screen-single-post';
  static const String screenStoryViewer = 'it-screen-story-viewer';
  static const String screenSingleShort = 'it-screen-single-short';
  static const String screenMarketDetail = 'it-screen-market-detail';
  static const String screenJobDetail = 'it-screen-job-detail';
  static const String screenScholarshipDetail = 'it-screen-scholarship-detail';
  static const String screenPracticeExamPreview =
      'it-screen-practice-exam-preview';
  static const String screenMyQr = 'it-screen-my-qr';
  static const String storyRow = 'it-story-row';

  static const String actionOpenNotifications = 'it-action-open-notifications';
  static const String actionShortBack = 'it-action-short-back';
  static const String actionFeedCreate = 'it-action-feed-create';
  static const String actionProfileOpenSettings =
      'it-action-profile-open-settings';
  static const String actionProfileOpenQr = 'it-action-profile-open-qr';
  static const String actionProfileOpenChat = 'it-action-profile-open-chat';
  static const String actionProfileEdit = 'it-action-profile-edit';
  static const String actionSettingsSignOut = 'it-action-settings-sign-out';
  static const String actionEditProfileUpdate = 'it-action-edit-profile-update';
  static const String actionPostCreatorPublish =
      'it-action-post-creator-publish';
  static const String actionCommentSend = 'it-action-comment-send';
  static const String actionCommentGifPicker = 'it-action-comment-gif-picker';
  static const String actionCommentClearReply = 'it-action-comment-clear-reply';
  static const String actionNotificationsMore = 'it-action-notifications-more';
  static const String actionNotificationsMarkAllRead =
      'it-action-notifications-mark-all-read';
  static const String actionNotificationsDeleteAll =
      'it-action-notifications-delete-all';
  static const String actionChatCreate = 'it-action-chat-create';
  static const String actionChatAttach = 'it-action-chat-attach';
  static const String actionChatGifPicker = 'it-action-chat-gif-picker';
  static const String actionChatCamera = 'it-action-chat-camera';
  static const String actionChatSend = 'it-action-chat-send';
  static const String actionChatMic = 'it-action-chat-mic';
  static const String actionStoryOpenComments = 'it-action-story-open-comments';
  static const String actionStoryCommentGifPicker =
      'it-action-story-comment-gif-picker';
  static const String actionStoryCommentSend = 'it-action-story-comment-send';
  static const String actionStoryCommentClearGif =
      'it-action-story-comment-clear-gif';
  static const String actionStoryLike = 'it-action-story-like';
  static const String profileFollowersCounter = 'it-profile-followers-counter';
  static const String profileFollowingCounter = 'it-profile-following-counter';
  static const String inputEditProfileFirstName =
      'it-input-edit-profile-first-name';
  static const String inputEditProfileLastName =
      'it-input-edit-profile-last-name';
  static const String inputComment = 'it-input-comment';
  static const String inputChatSearch = 'it-input-chat-search';
  static const String inputChatComposer = 'it-input-chat-composer';
  static const String inputStoryComment = 'it-input-story-comment';
  static const String chatTabAll = 'it-chat-tab-all';
  static const String chatTabUnread = 'it-chat-tab-unread';
  static const String chatTabArchive = 'it-chat-tab-archive';

  static String practiceExamOpen(String docId) =>
      'it-practice-exam-open-$docId';

  static String practiceExamCta(String docId) => 'it-practice-exam-cta-$docId';

  static String questionBankCategory(String category) =>
      'it-question-bank-category-$category';

  static String educationActionMenu(String tabId) =>
      'it-education-action-menu-$tabId';
  static String educationTab(String tabId) => 'it-education-tab-$tabId';
  static String pageLineBarItem(String pageName, int index) =>
      'it-page-line-bar-$pageName-$index';

  static String composerText(int index) => 'it-composer-text-$index';
  static String feedLikeButton(String docId) => 'it-feed-like-$docId';
  static String feedCommentButton(String docId) => 'it-feed-comment-$docId';
  static String commentItem(String commentId) => 'it-comment-item-$commentId';
  static String commentReplyButton(String commentId) =>
      'it-comment-reply-$commentId';
  static String commentDeleteButton(String commentId) =>
      'it-comment-delete-$commentId';
  static String commentLikeButton(String commentId) =>
      'it-comment-like-$commentId';
  static String chatTile(String chatId) => 'it-chat-tile-$chatId';
  static String notificationItem(String notificationId) =>
      'it-notification-item-$notificationId';
  static String storyReaction(int index) => 'it-story-reaction-$index';
  static String marketItem(String itemId) => 'it-market-item-$itemId';
  static String jobItem(String jobId) => 'it-job-item-$jobId';
  static String scholarshipItem(String scholarshipId) =>
      'it-scholarship-item-$scholarshipId';

  static const String marketTopActionViewMode = 'it-market-top-action-view';
  static const String marketTopActionSort = 'it-market-top-action-sort';
  static const String marketTopActionFilter = 'it-market-top-action-filter';
}
