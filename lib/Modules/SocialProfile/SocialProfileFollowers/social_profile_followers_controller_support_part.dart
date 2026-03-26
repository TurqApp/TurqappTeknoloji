part of 'social_profile_followers_controller.dart';

const Duration _socialProfileFollowersRelationCacheTtl = Duration(seconds: 30);
const Duration _socialProfileFollowersRelationCacheStaleRetention =
    Duration(minutes: 3);
const int _socialProfileFollowersMaxRelationCacheEntries = 400;
final Map<String, _RelationListCacheEntry>
    _socialProfileFollowersRelationCache = <String, _RelationListCacheEntry>{};

void _configureSocialProfileFollowersController(
  SocialProfileFollowersController controller, {
  required int initialPage,
  required String userID,
}) {
  controller.userID = userID;
  controller.selection.value = initialPage;
  controller.pageController = PageController(initialPage: initialPage);
}

void _handleSocialProfileFollowersControllerOnInit(
  SocialProfileFollowersController controller,
) {
  controller._handleOnInit();
}

void _handleSocialProfileFollowersControllerOnClose(
  SocialProfileFollowersController controller,
) {
  controller._handleOnClose();
}
