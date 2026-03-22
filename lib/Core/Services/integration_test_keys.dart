class IntegrationTestKeys {
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
  static const String screenShort = 'it-screen-short';
  static const String screenChat = 'it-screen-chat';
  static const String screenEducation = 'it-screen-education';
  static const String screenNotifications = 'it-screen-notifications';
  static const String screenFollowingFollowers =
      'it-screen-following-followers';
  static const String screenSettings = 'it-screen-settings';
  static const String screenEditProfile = 'it-screen-edit-profile';
  static const String screenPostCreator = 'it-screen-post-creator';

  static const String actionOpenNotifications = 'it-action-open-notifications';
  static const String actionShortBack = 'it-action-short-back';
  static const String actionFeedCreate = 'it-action-feed-create';
  static const String actionProfileOpenSettings =
      'it-action-profile-open-settings';
  static const String actionProfileEdit = 'it-action-profile-edit';
  static const String actionSettingsSignOut = 'it-action-settings-sign-out';
  static const String actionEditProfileUpdate =
      'it-action-edit-profile-update';
  static const String actionPostCreatorPublish =
      'it-action-post-creator-publish';
  static const String actionCommentSend = 'it-action-comment-send';
  static const String profileFollowersCounter = 'it-profile-followers-counter';
  static const String profileFollowingCounter = 'it-profile-following-counter';
  static const String inputEditProfileFirstName =
      'it-input-edit-profile-first-name';
  static const String inputEditProfileLastName =
      'it-input-edit-profile-last-name';
  static const String inputComment = 'it-input-comment';

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

  static const String marketTopActionViewMode = 'it-market-top-action-view';
  static const String marketTopActionSort = 'it-market-top-action-sort';
  static const String marketTopActionFilter = 'it-market-top-action-filter';
}
