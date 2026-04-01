part of 'typesense_user_card_cache_service.dart';

class _CachedUserCardsResult {
  _CachedUserCardsResult({required Map<String, Map<String, dynamic>> cards, required this.cachedAt})
    : cards = cards.map(
        (key, value) => MapEntry(
          key,
          value.map(
            (nestedKey, nestedValue) => MapEntry(
              nestedKey,
              _cloneCardValue(nestedValue),
            ),
          ),
        ),
      );

  final Map<String, Map<String, dynamic>> cards;
  final DateTime cachedAt;
  bool get isFresh =>
      DateTime.now().difference(cachedAt) < _typesenseUserCardCacheTtl;
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
