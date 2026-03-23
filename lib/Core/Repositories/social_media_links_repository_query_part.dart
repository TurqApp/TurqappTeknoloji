part of 'social_media_links_repository.dart';

extension SocialMediaLinksRepositoryQueryPart on SocialMediaLinksRepository {
  Future<List<SocialMediaModel>> _getLinksImpl(
    String uid, {
    required bool preferCache,
    required bool forceRefresh,
    required bool cacheOnly,
  }) async {
    if (uid.isEmpty) return const <SocialMediaModel>[];

    if (!forceRefresh) {
      final memory = _getFromMemoryImpl(uid, allowStale: false);
      if (preferCache && memory != null) {
        return memory;
      }
      final disk = await _getFromPrefsEntryImpl(uid, allowStale: false);
      if (preferCache && disk != null) {
        _memory[uid] = _CachedSocialMediaLinks(
          items: _cloneItemsImpl(disk.items),
          cachedAt: disk.cachedAt,
        );
        return _cloneItemsImpl(disk.items);
      }
    }

    if (cacheOnly) return const <SocialMediaModel>[];

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('SosyalMedyaLinkleri')
        .orderBy('sira')
        .get();
    final list = snap.docs.map(SocialMediaModel.fromFirestore).toList();
    await setLinks(uid, list);
    return list;
  }
}
