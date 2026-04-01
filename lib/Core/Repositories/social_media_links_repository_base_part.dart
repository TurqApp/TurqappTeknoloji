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

class SocialMediaLinksRepository extends _SocialMediaLinksRepositoryBase {
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'social_media_links_repository_v1';

  static SocialMediaLinksRepository? maybeFind() =>
      _maybeFindSocialMediaLinksRepository();

  static SocialMediaLinksRepository ensure() =>
      _ensureSocialMediaLinksRepository();
}

abstract class _SocialMediaLinksRepositoryBase extends GetxService {
  final _state = _SocialMediaLinksRepositoryState();

  @override
  void onInit() {
    super.onInit();
    _handleSocialMediaLinksRepositoryInit(this as SocialMediaLinksRepository);
  }
}

extension SocialMediaLinksRepositoryFieldsPart on SocialMediaLinksRepository {
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
  Map<String, _CachedSocialMediaLinks> get _memory => _state.memory;
}

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
