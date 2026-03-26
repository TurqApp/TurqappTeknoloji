part of 'social_profile_followers_controller.dart';

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
