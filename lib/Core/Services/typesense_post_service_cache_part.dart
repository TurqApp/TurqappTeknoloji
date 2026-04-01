part of 'typesense_post_service.dart';

extension TypesensePostServiceCachePart on TypesensePostService {
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
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final prefsKey = _prefsKey(cacheKey);
    try {
      final raw = prefs?.getString(prefsKey);
      if (raw == null || raw.isEmpty) return null;
      final data = jsonDecode(raw);
      if (data is! Map) {
        await prefs?.remove(prefsKey);
        return null;
      }
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
          final card = _cloneTypesensePostCard(
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
      final cached = _CachedPostCardsResult(
        cards: _cloneTypesensePostCards(cards),
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
            'cards': _cloneTypesensePostCards(cards),
          }),
        );
      }
      _memory[cacheKey] = cached;
      return cached;
    } catch (_) {
      await prefs?.remove(prefsKey);
      return null;
    }
  }

  Future<void> _performStore(
    String cacheKey,
    Map<String, Map<String, dynamic>> cards,
  ) async {
    final cached = _CachedPostCardsResult(
      cards: _cloneTypesensePostCards(cards),
      cachedAt: DateTime.now(),
    );
    _memory[cacheKey] = cached;
    try {
      _prefs ??= await SharedPreferences.getInstance();
      await _prefs?.setString(
        _prefsKey(cacheKey),
        jsonEncode(<String, dynamic>{
          'cachedAt': cached.cachedAt.millisecondsSinceEpoch,
          'cards': _cloneTypesensePostCards(cards),
        }),
      );
    } catch (_) {}
  }

  Map<String, Map<String, dynamic>> _cloneTypesensePostCards(
    Map<String, Map<String, dynamic>> source,
  ) {
    return source.map(
      (key, value) => MapEntry(key, _cloneTypesensePostCard(value)),
    );
  }

  Map<String, dynamic> _cloneTypesensePostCard(Map<String, dynamic> source) {
    return source.map(
      (key, value) => MapEntry(key, _cloneTypesensePostCardValue(value)),
    );
  }

  dynamic _cloneTypesensePostCardValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, nestedValue) => MapEntry(
          key.toString(),
          _cloneTypesensePostCardValue(nestedValue),
        ),
      );
    }
    if (value is List) {
      return value.map(_cloneTypesensePostCardValue).toList(growable: false);
    }
    return value;
  }
}
