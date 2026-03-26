part of 'social_media_links_repository.dart';

class _CachedSocialMediaLinks {
  final List<SocialMediaModel> items;
  final DateTime cachedAt;

  const _CachedSocialMediaLinks({
    required this.items,
    required this.cachedAt,
  });
}

class _SocialMediaLinksRepositoryState {
  SharedPreferences? prefs;
  final memory = <String, _CachedSocialMediaLinks>{};
}

extension SocialMediaLinksRepositoryFieldsPart on SocialMediaLinksRepository {
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
  Map<String, _CachedSocialMediaLinks> get _memory => _state.memory;
}
