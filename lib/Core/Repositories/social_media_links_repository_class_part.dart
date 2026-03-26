part of 'social_media_links_repository.dart';

class SocialMediaLinksRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'social_media_links_repository_v1';

  final _state = _SocialMediaLinksRepositoryState();

  static SocialMediaLinksRepository? maybeFind() =>
      _maybeFindSocialMediaLinksRepository();

  static SocialMediaLinksRepository ensure() =>
      _ensureSocialMediaLinksRepository();

  @override
  void onInit() {
    super.onInit();
    _handleSocialMediaLinksRepositoryInit(this);
  }
}
