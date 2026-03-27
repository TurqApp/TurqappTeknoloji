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

SocialProfileFollowersController ensureSocialProfileFollowersController({
  required int initialPage,
  required String userID,
  String? tag,
  bool permanent = false,
}) =>
    _ensureSocialProfileFollowersController(
      initialPage: initialPage,
      userID: userID,
      tag: tag,
      permanent: permanent,
    );

SocialProfileFollowersController? maybeFindSocialProfileFollowersController({
  String? tag,
}) =>
    _maybeFindSocialProfileFollowersController(tag: tag);

SocialProfileFollowersController _ensureSocialProfileFollowersController({
  required int initialPage,
  required String userID,
  String? tag,
  bool permanent = false,
}) {
  final existing = _maybeFindSocialProfileFollowersController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    SocialProfileFollowersController(
      initialPage: initialPage,
      userID: userID,
    ),
    tag: tag,
    permanent: permanent,
  );
}

SocialProfileFollowersController? _maybeFindSocialProfileFollowersController({
  String? tag,
}) {
  final isRegistered =
      Get.isRegistered<SocialProfileFollowersController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<SocialProfileFollowersController>(tag: tag);
}
