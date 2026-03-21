class IntegrationTestKeys {
  static const String navBarRoot = 'it-nav-bar-root';
  static const String navFeed = 'it-nav-feed';
  static const String navExplore = 'it-nav-explore';
  static const String navShort = 'it-nav-short';
  static const String navEducation = 'it-nav-education';
  static const String navProfile = 'it-nav-profile';

  static const String screenFeed = 'it-screen-feed';
  static const String screenExplore = 'it-screen-explore';
  static const String screenProfile = 'it-screen-profile';
  static const String screenShort = 'it-screen-short';
  static const String screenNotifications = 'it-screen-notifications';
  static const String screenFollowingFollowers =
      'it-screen-following-followers';

  static const String actionOpenNotifications = 'it-action-open-notifications';
  static const String actionShortBack = 'it-action-short-back';
  static const String profileFollowersCounter = 'it-profile-followers-counter';
  static const String profileFollowingCounter = 'it-profile-following-counter';

  static String practiceExamOpen(String docId) =>
      'it-practice-exam-open-$docId';

  static String practiceExamCta(String docId) =>
      'it-practice-exam-cta-$docId';

  static String questionBankCategory(String category) =>
      'it-question-bank-category-$category';
}
