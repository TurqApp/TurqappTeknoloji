part of 'social_media_links_repository.dart';

class SocialMediaLinksRepository extends _SocialMediaLinksRepositoryBase {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'social_media_links_repository_v1';

  static SocialMediaLinksRepository? maybeFind() =>
      _maybeFindSocialMediaLinksRepository();

  static SocialMediaLinksRepository ensure() =>
      _ensureSocialMediaLinksRepository();
}
