import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/typesense_user_service.dart';

class TypesenseUserCardCacheService extends GetxService {
  static const Duration _ttl = Duration(minutes: 15);
  static const String _prefsPrefix = 'typesense_user_cards_v1';

  final Map<String, _CachedUserCardsResult> _memory =
      <String, _CachedUserCardsResult>{};
  SharedPreferences? _prefs;

  static TypesenseUserCardCacheService? maybeFind() {
    if (!Get.isRegistered<TypesenseUserCardCacheService>()) return null;
    return Get.find<TypesenseUserCardCacheService>();
  }

  static TypesenseUserCardCacheService _ensureService() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TypesenseUserCardCacheService(), permanent: true);
  }

  static TypesenseUserCardCacheService ensure() {
    return _ensureService();
  }

  Future<Map<String, Map<String, dynamic>>> getUserCardsByIds(
    List<String> ids, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
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
    _memory.clear();
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('$_prefsPrefix:'))
        .toList(growable: false);
    for (final key in keys) {
      await prefs.remove(key);
    }
  }

  _CachedUserCardsResult? _getFromMemory(String cacheKey) {
    final cached = _memory[cacheKey];
    if (cached == null) return null;
    if (!cached.isFresh) {
      _memory.remove(cacheKey);
      return null;
    }
    return cached;
  }

  Future<_CachedUserCardsResult?> _getFromPrefs(String cacheKey) async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
      final raw = _prefs?.getString(_prefsKey(cacheKey));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final data = Map<String, dynamic>.from(decoded.cast<dynamic, dynamic>());
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
      final cached = _CachedUserCardsResult(
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

  Future<void> _store(
    String cacheKey,
    Map<String, Map<String, dynamic>> cards,
  ) async {
    final cached = _CachedUserCardsResult(
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

  String _cacheKey(List<String> ids) {
    final sorted = [...ids]..sort();
    return sorted.join('|');
  }

  String _prefsKey(String cacheKey) => '$_prefsPrefix:$cacheKey';
}

class _CachedUserCardsResult {
  const _CachedUserCardsResult({
    required this.cards,
    required this.cachedAt,
  });

  final Map<String, Map<String, dynamic>> cards;
  final DateTime cachedAt;

  bool get isFresh =>
      DateTime.now().difference(cachedAt) < TypesenseUserCardCacheService._ttl;
}
