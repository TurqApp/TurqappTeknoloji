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

  Future<List<SocialMediaModel>> getLinks(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _getLinksImpl(
        uid,
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<bool> hasFreshCacheEntry(String uid) => _hasFreshCacheEntryImpl(uid);

  Future<void> setLinks(String uid, List<SocialMediaModel> items) =>
      _setLinksImpl(uid, items);

  Future<void> saveLink(
    String uid, {
    required SocialMediaModel model,
  }) =>
      _saveLinkImpl(uid, model: model);

  Future<void> deleteLink(String uid, String docId) =>
      _deleteLinkImpl(uid, docId);

  Future<void> reorderLinks(String uid, List<SocialMediaModel> items) =>
      _reorderLinksImpl(uid, items);

  Future<void> invalidate(String uid) => _invalidateImpl(uid);
}
