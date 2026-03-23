part of 'typesense_post_service.dart';

extension TypesensePostServiceCachePart on TypesensePostService {
  Future<void> _performInvalidatePostId(String postId) async {
    final cleaned = postId.trim();
    if (cleaned.isEmpty) return;
    _memory.removeWhere((cacheKey, _) => cacheKey.split('|').contains(cleaned));
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs.getKeys().where((key) {
      if (!key.startsWith('${TypesensePostService._prefsPrefix}:')) {
        return false;
      }
      final scopedKey =
          key.substring('${TypesensePostService._prefsPrefix}:'.length);
      return scopedKey.split('|').contains(cleaned);
    }).toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  Future<void> _performInvalidateAll() async {
    _memory.clear();
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs
        .getKeys()
        .where(
          (key) => key.startsWith('${TypesensePostService._prefsPrefix}:'),
        )
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  _CachedPostCardsResult? _performGetFromMemory(String cacheKey) {
    final cached = _memory[cacheKey];
    if (cached == null) return null;
    if (!cached.isFresh) {
      _memory.remove(cacheKey);
      return null;
    }
    return cached;
  }

  Future<_CachedPostCardsResult?> _performGetFromPrefs(String cacheKey) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs?.getString(_prefsKey(cacheKey));
      if (raw == null || raw.isEmpty) return null;
      final data = jsonDecode(raw);
      if (data is! Map) return null;
      final cachedAtMs = (data['cachedAt'] as num?)?.toInt() ?? 0;
      final cardsRaw = data['cards'];
      if (cachedAtMs <= 0 || cardsRaw is! Map) return null;
      final cards = <String, Map<String, dynamic>>{};
      cardsRaw.forEach((key, value) {
        if (value is Map) {
          cards[key.toString()] = Map<String, dynamic>.from(
            value.cast<dynamic, dynamic>(),
          );
        }
      });
      final cached = _CachedPostCardsResult(
        cards: cards,
        cachedAt: DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
      );
      if (!cached.isFresh) {
        await _prefs?.remove(_prefsKey(cacheKey));
        return null;
      }
      _memory[cacheKey] = cached;
      return cached;
    } catch (_) {
      return null;
    }
  }

  Future<void> _performStore(
    String cacheKey,
    Map<String, Map<String, dynamic>> cards,
  ) async {
    final cached = _CachedPostCardsResult(
      cards: Map<String, Map<String, dynamic>>.from(cards),
      cachedAt: DateTime.now(),
    );
    _memory[cacheKey] = cached;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(
        _prefsKey(cacheKey),
        jsonEncode(<String, dynamic>{
          'cachedAt': cached.cachedAt.millisecondsSinceEpoch,
          'cards': cards,
        }),
      );
    } catch (_) {}
  }
}
