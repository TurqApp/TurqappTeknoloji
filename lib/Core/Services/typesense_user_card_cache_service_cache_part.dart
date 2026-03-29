part of 'typesense_user_card_cache_service.dart';

class _TypesenseUserCardCacheServiceCachePart {
  final TypesenseUserCardCacheService service;

  const _TypesenseUserCardCacheServiceCachePart(this.service);

  Future<Map<String, Map<String, dynamic>>> getUserCardsByIds(
    List<String> ids, {
    required bool preferCache,
    required bool forceRefresh,
    required bool cacheOnly,
  }) async {
    final cleaned = ids
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleaned.isEmpty) return const <String, Map<String, dynamic>>{};

    final cacheKey = _cacheKey(cleaned);
    if (!forceRefresh && preferCache) {
      final memoryHit = _getFromMemory(cacheKey);
      if (memoryHit != null) return memoryHit.cards;

      final diskHit = await _getFromPrefs(cacheKey);
      if (diskHit != null) return diskHit.cards;
    }

    if (cacheOnly) return const <String, Map<String, dynamic>>{};

    final cards =
        await TypesenseUserService.instance.getUserCardsByIds(cleaned);
    await _store(cacheKey, cards);
    return cards;
  }

  Future<void> invalidateAll() async {
    service._memory.clear();
    service._prefs ??= await SharedPreferences.getInstance();
    final prefs = service._prefs;
    if (prefs == null) return;
    final keys = prefs
        .getKeys()
        .where(
          (key) => key.startsWith('$_typesenseUserCardPrefsPrefix:'),
        )
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  _CachedUserCardsResult? _getFromMemory(String cacheKey) {
    final cached = service._memory[cacheKey];
    if (cached == null) return null;
    if (!cached.isFresh) {
      service._memory.remove(cacheKey);
      return null;
    }
    return cached;
  }

  Future<_CachedUserCardsResult?> _getFromPrefs(String cacheKey) async {
    service._prefs ??= await SharedPreferences.getInstance();
    final prefs = service._prefs;
    final prefsKey = _prefsKey(cacheKey);
    try {
      final raw = prefs?.getString(prefsKey);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final data = Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
      final cachedAtMs = (data['cachedAt'] as num?)?.toInt() ?? 0;
      final cardsRaw = data['cards'];
      if (cachedAtMs <= 0 || cardsRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cards = <String, Map<String, dynamic>>{};
      cardsRaw.forEach((key, value) {
        if (value is Map) {
          cards[key.toString()] = Map<String, dynamic>.from(
            value.cast<dynamic, dynamic>(),
          );
        }
      });
      final cached = _CachedUserCardsResult(
        cards: cards,
        cachedAt: DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
      );
      if (!cached.isFresh) {
        await prefs?.remove(prefsKey);
        return null;
      }
      service._memory[cacheKey] = cached;
      return cached;
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<void> _store(
    String cacheKey,
    Map<String, Map<String, dynamic>> cards,
  ) async {
    final cached = _CachedUserCardsResult(
      cards: Map<String, Map<String, dynamic>>.from(cards),
      cachedAt: DateTime.now(),
    );
    service._memory[cacheKey] = cached;
    try {
      service._prefs ??= await SharedPreferences.getInstance();
      await service._prefs?.setString(
        _prefsKey(cacheKey),
        jsonEncode(<String, dynamic>{
          'cachedAt': cached.cachedAt.millisecondsSinceEpoch,
          'cards': cards,
        }),
      );
    } catch (_) {}
  }

  String _cacheKey(List<String> ids) {
    final sorted = [...ids]..sort();
    return sorted.join('|');
  }

  String _prefsKey(String cacheKey) =>
      '$_typesenseUserCardPrefsPrefix:$cacheKey';
}
