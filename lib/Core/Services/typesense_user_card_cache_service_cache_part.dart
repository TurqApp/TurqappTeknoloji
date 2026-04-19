part of 'typesense_user_card_cache_service.dart';

class _TypesenseUserCardCacheServiceCachePart {
  final TypesenseUserCardCacheService service;

  const _TypesenseUserCardCacheServiceCachePart(this.service);

  int _asInt(dynamic value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;
      final parsedNum = num.tryParse(value.trim());
      if (parsedNum != null) return parsedNum.toInt();
    }
    return fallback;
  }

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
      if (memoryHit != null) return _cloneCards(memoryHit.cards);

      final diskHit = await _getFromPrefs(cacheKey);
      if (diskHit != null) return _cloneCards(diskHit.cards);
    }

    if (cacheOnly) return const <String, Map<String, dynamic>>{};

    final inFlight = service._inFlight[cacheKey];
    if (inFlight != null) {
      return _cloneCards(await inFlight);
    }

    final future = () async {
      final cards = await TypesenseUserService.instance.getUserCardsByIds(
        cleaned,
      );
      await _store(cacheKey, cards);
      return _cloneCards(cards);
    }();
    service._inFlight[cacheKey] = future;
    try {
      return _cloneCards(await future);
    } finally {
      if (identical(service._inFlight[cacheKey], future)) {
        service._inFlight.remove(cacheKey);
      }
    }
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
      final cachedAtMs = _asInt(data['cachedAt']);
      final cardsRaw = data['cards'];
      if (cachedAtMs <= 0 || cardsRaw is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
      final cards = <String, Map<String, dynamic>>{};
      var shouldPrune = false;
      cardsRaw.forEach((key, value) {
        if (value is Map) {
          final card = _cloneCard(
            Map<String, dynamic>.from(
              value.cast<dynamic, dynamic>(),
            ),
          );
          if (card.isEmpty) {
            shouldPrune = true;
            return;
          }
          cards[key.toString()] = card;
          return;
        }
        shouldPrune = true;
      });
      final cached = _CachedUserCardsResult(
        cards: _cloneCards(cards),
        cachedAt: DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
      );
      if (!cached.isFresh) {
        await prefs?.remove(prefsKey);
        return null;
      }
      if (shouldPrune) {
        if (cards.isEmpty) {
          await prefs?.remove(prefsKey);
          return null;
        }
        await prefs?.setString(
          prefsKey,
          jsonEncode(<String, dynamic>{
            'cachedAt': cachedAtMs,
            'cards': _cloneCards(cards),
          }),
        );
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
      cards: _cloneCards(cards),
      cachedAt: DateTime.now(),
    );
    service._memory[cacheKey] = cached;
    try {
      service._prefs ??= await SharedPreferences.getInstance();
      await service._prefs?.setString(
        _prefsKey(cacheKey),
        jsonEncode(<String, dynamic>{
          'cachedAt': cached.cachedAt.millisecondsSinceEpoch,
          'cards': _cloneCards(cards),
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

  Map<String, Map<String, dynamic>> _cloneCards(
    Map<String, Map<String, dynamic>> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key, _cloneCard(value)),
    );
  }

  Map<String, dynamic> _cloneCard(Map<String, dynamic> source) {
    return source.map(
      (key, value) => MapEntry(key, _cloneCardValue(value)),
    );
  }

  dynamic _cloneCardValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneCardValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneCardValue).toList(growable: false);
    }
    return value;
  }
}
