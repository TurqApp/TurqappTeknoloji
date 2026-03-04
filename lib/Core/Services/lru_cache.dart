import 'dart:collection';

/// TTL'li in-memory LRU cache.
///
/// Kullanım örnekleri:
/// ```dart
/// // Singleton
/// final privacyCache = LRUCache<String, bool>(capacity: 500, ttl: Duration(minutes: 10));
///
/// // Oku
/// final isPrivate = privacyCache.get('uid123');  // null → miss
///
/// // Yaz
/// privacyCache.put('uid123', false);
///
/// // Toplu yaz
/// privacyCache.putAll({'uid1': false, 'uid2': true});
///
/// // Sadece eksik key'leri döndür
/// final missing = privacyCache.missingKeys(['uid1', 'uid2', 'uid3']);
/// ```
class LRUCache<K, V> {
  final int capacity;
  final Duration ttl;

  /// LinkedHashMap: insertion order korunur → LRU eviction için son eklenen sonda
  final _map = LinkedHashMap<K, _CacheEntry<V>>();

  LRUCache({required this.capacity, required this.ttl})
      : assert(capacity > 0, 'capacity > 0 olmalı');

  /// Değeri oku. TTL aşıldıysa null döner (ve entry silinir).
  V? get(K key) {
    final entry = _map[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiry)) {
      _map.remove(key);
      return null;
    }

    // LRU: erişilen entry'yi sona taşı
    _map.remove(key);
    _map[key] = entry;
    return entry.value;
  }

  /// Değeri yaz. Kapasite aşılırsa en eski (LRU) entry silinir.
  void put(K key, V value) {
    _map.remove(key); // önce kaldır (order yenileme)
    if (_map.length >= capacity) {
      _map.remove(_map.keys.first); // en eski
    }
    _map[key] = _CacheEntry(value, DateTime.now().add(ttl));
  }

  /// Birden fazla key-value çiftini toplu yaz.
  void putAll(Map<K, V> entries) {
    for (final e in entries.entries) {
      put(e.key, e.value);
    }
  }

  /// Verilen key listesinden cache'de bulunmayanları döndürür (fetch edilmesi gerekenler).
  List<K> missingKeys(Iterable<K> keys) {
    final now = DateTime.now();
    final missing = <K>[];
    for (final k in keys) {
      final entry = _map[k];
      if (entry == null || now.isAfter(entry.expiry)) {
        if (entry != null) _map.remove(k); // expired temizle
        missing.add(k);
      }
    }
    return missing;
  }

  /// Belirli bir key'i geçersiz kıl.
  void invalidate(K key) => _map.remove(key);

  /// Koşula uyan tüm entry'leri temizle.
  void invalidateWhere(bool Function(K key, V value) test) {
    _map.removeWhere((k, e) => test(k, e.value));
  }

  /// Tüm cache'i temizle.
  void clear() => _map.clear();

  int get length => _map.length;
  bool get isEmpty => _map.isEmpty;
  bool containsKey(K key) {
    final entry = _map[key];
    if (entry == null) return false;
    if (DateTime.now().isAfter(entry.expiry)) {
      _map.remove(key);
      return false;
    }
    return true;
  }
}

class _CacheEntry<V> {
  final V value;
  final DateTime expiry;
  _CacheEntry(this.value, this.expiry);
}
