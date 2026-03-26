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

extension SocialMediaLinksRepositoryFacadePart on SocialMediaLinksRepository {
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
