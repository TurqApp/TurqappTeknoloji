part of 'social_media_links_repository.dart';

extension SocialMediaLinksRepositoryStoragePart on SocialMediaLinksRepository {
  Future<void> _setLinksImpl(String uid, List<SocialMediaModel> items) async {
    if (uid.isEmpty) return;
    final cloned = _cloneItemsImpl(items);
    final cachedAt = DateTime.now();
    _memory[uid] = _CachedSocialMediaLinks(items: cloned, cachedAt: cachedAt);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKeyImpl(uid),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'items': cloned
            .map(
              (e) => {
                'docID': e.docID,
                'title': e.title,
                'url': e.url,
                'sira': e.sira,
                'logo': e.logo,
              },
            )
            .toList(),
      }),
    );
  }

  Future<void> _invalidateImpl(String uid) async {
    _memory.remove(uid);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKeyImpl(uid));
  }

  List<SocialMediaModel>? _getFromMemoryImpl(
    String uid, {
    required bool allowStale,
  }) {
    final entry = _memory[uid];
    if (entry == null) return null;
    final fresh =
        DateTime.now().difference(entry.cachedAt) <=
        SocialMediaLinksRepository._ttl;
    if (!fresh && !allowStale) {
      _memory.remove(uid);
      return null;
    }
    return _cloneItemsImpl(entry.items);
  }

  Future<_CachedSocialMediaLinks?> _getFromPrefsEntryImpl(
    String uid, {
    required bool allowStale,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = _prefsKeyImpl(uid);
    final raw = prefs?.getString(prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decodedRaw = jsonDecode(raw);
      if (decodedRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final decoded = Map<String, dynamic>.from(
        decodedRaw.cast<dynamic, dynamic>(),
      );
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final list =
          (decoded['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      if (ts <= 0) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final fresh =
          DateTime.now().difference(cachedAt) <=
          SocialMediaLinksRepository._ttl;
      if (!fresh) {
        if (!allowStale) {
          await prefs?.remove(prefsKey);
        }
        return null;
      }
      return _CachedSocialMediaLinks(
        cachedAt: cachedAt,
        items: list
            .map(
              (e) => SocialMediaModel(
                docID: (e['docID'] ?? '').toString(),
                title: (e['title'] ?? '').toString(),
                url: (e['url'] ?? '').toString(),
                sira: (e['sira'] as num?) ?? 0,
                logo: (e['logo'] ?? '').toString(),
              ),
            )
            .toList(growable: false),
      );
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  List<SocialMediaModel> _cloneItemsImpl(List<SocialMediaModel> items) {
    return items
        .map(
          (e) => SocialMediaModel(
            docID: e.docID,
            title: e.title,
            url: e.url,
            sira: e.sira,
            logo: e.logo,
          ),
        )
        .toList(growable: false);
  }

  String _prefsKeyImpl(String uid) =>
      '${SocialMediaLinksRepository._prefsPrefix}:$uid';
}
