part of 'social_media_links_repository.dart';

abstract class _SocialMediaLinksRepositoryBase extends GetxService {
  final _state = _SocialMediaLinksRepositoryState();

  @override
  void onInit() {
    super.onInit();
    _handleSocialMediaLinksRepositoryInit(this as SocialMediaLinksRepository);
  }
}
