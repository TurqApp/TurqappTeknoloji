part of 'social_media_links_repository.dart';

SocialMediaLinksRepository? _maybeFindSocialMediaLinksRepository() {
  final isRegistered = Get.isRegistered<SocialMediaLinksRepository>();
  if (!isRegistered) return null;
  return Get.find<SocialMediaLinksRepository>();
}

SocialMediaLinksRepository _ensureSocialMediaLinksRepository() {
  final existing = _maybeFindSocialMediaLinksRepository();
  if (existing != null) return existing;
  return Get.put(SocialMediaLinksRepository(), permanent: true);
}

void _handleSocialMediaLinksRepositoryInit(
  SocialMediaLinksRepository repository,
) {
  SharedPreferences.getInstance().then((prefs) {
    repository._prefs = prefs;
  });
}
