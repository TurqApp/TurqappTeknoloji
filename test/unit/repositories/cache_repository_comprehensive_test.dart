import 'package:flutter_test/flutter_test.dart';

class CacheService {
  final Map<String, dynamic> _store = <String, dynamic>{};
  final Map<String, DateTime> _timestamps = <String, DateTime>{};

  void save(String key, dynamic value) {
    _store[key] = _cloneValue(value);
    _timestamps[key] = DateTime.now();
  }

  void saveWithTime(String key, dynamic value, DateTime time) {
    _store[key] = _cloneValue(value);
    _timestamps[key] = time;
  }

  dynamic get(String key) => _cloneValue(_store[key]);

  DateTime? getTime(String key) => _timestamps[key];

  void clear() {
    _store.clear();
    _timestamps.clear();
  }

  void saveRaw(String key, dynamic value) {
    _store[key] = value;
  }

  dynamic _cloneValue(dynamic value) {
    if (value is List<String>) {
      return List<String>.from(value);
    }
    if (value is List) {
      return List<dynamic>.from(value);
    }
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<dynamic, dynamic>.from(value);
    }
    return value;
  }
}

class FakeApi {
  bool shouldFail = false;
  List<String> data = <String>['post1', 'post2'];

  Future<List<String>> fetchFeed() async {
    await Future<void>.delayed(const Duration(milliseconds: 100));

    if (shouldFail) {
      throw Exception('Network error');
    }

    return List<String>.from(data);
  }
}

class Repository {
  Repository(this.cache, this.api);

  final CacheService cache;
  final FakeApi api;

  Future<List<String>> getFeed() async {
    final cached = cache.get('feed');

    try {
      final fresh = _normalizeFeed(await api.fetchFeed());
      cache.save('feed', fresh);
      return List<String>.from(fresh);
    } catch (_) {
      if (cached is List) {
        return List<String>.from(cached);
      }
      rethrow;
    }
  }

  Future<List<String>> getFeedWithExpiry(Duration maxAge) async {
    final cached = cache.get('feed');
    final time = cache.getTime('feed');

    if (cached is List && time != null) {
      final isExpired = DateTime.now().difference(time) > maxAge;
      if (!isExpired) {
        return List<String>.from(cached);
      }
    }

    final fresh = _normalizeFeed(await api.fetchFeed());
    cache.save('feed', fresh);
    return List<String>.from(fresh);
  }

  List<String> _normalizeFeed(List<String> items) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final item in items) {
      if (seen.add(item)) {
        normalized.add(item);
      }
    }
    return normalized;
  }
}

void main() {
  late CacheService cache;
  late FakeApi api;
  late Repository repo;

  setUp(() {
    cache = CacheService();
    api = FakeApi();
    repo = Repository(cache, api);
  });

  group('CACHE TEST SUITE', () {
    test('1. Cache save & read', () {
      cache.save('feed', <String>['a']);

      expect(cache.get('feed'), <String>['a']);
    });

    test('2. API success updates cache', () async {
      final result = await repo.getFeed();

      expect(result, <String>['post1', 'post2']);
      expect(cache.get('feed'), <String>['post1', 'post2']);
    });

    test('3. Offline uses cache', () async {
      cache.save('feed', <String>['cached_post']);
      api.shouldFail = true;

      final result = await repo.getFeed();

      expect(result, contains('cached_post'));
    });

    test('4. No cache + offline throws', () async {
      api.shouldFail = true;

      expect(() async => repo.getFeed(), throwsException);
    });

    test('5. Cache expiry not expired', () async {
      cache.saveWithTime('feed', <String>['fresh'], DateTime.now());

      final result = await repo.getFeedWithExpiry(const Duration(hours: 1));

      expect(result, <String>['fresh']);
    });

    test('6. Cache expiry expired triggers API', () async {
      cache.saveWithTime(
        'feed',
        <String>['old'],
        DateTime.now().subtract(const Duration(hours: 2)),
      );

      final result = await repo.getFeedWithExpiry(const Duration(hours: 1));

      expect(result, <String>['post1', 'post2']);
    });

    test('7. Cache cleared on logout', () {
      cache.save('user', <String, dynamic>{'id': 1});
      cache.clear();

      expect(cache.get('user'), isNull);
    });

    test('8. Corrupted cache safe fallback', () async {
      cache.saveRaw('feed', 'INVALID');

      final result = await repo.getFeed();

      expect(result, isNotEmpty);
      expect(result, <String>['post1', 'post2']);
    });

    test('9. Cache overwrite works', () async {
      cache.save('feed', <String>['old']);

      final result = await repo.getFeed();

      expect(result, <String>['post1', 'post2']);
      expect(cache.get('feed'), <String>['post1', 'post2']);
    });

    test('10. Concurrent requests consistency', () async {
      final results = await Future.wait<List<String>>(<Future<List<String>>>[
        repo.getFeed(),
        repo.getFeed(),
      ]);

      expect(results[0], results[1]);
    });

    test('11. Pagination no duplicate', () async {
      cache.save('feed', <String>['post1']);
      api.data = <String>['post1', 'post2', 'post2', 'post3'];

      final result = await repo.getFeed();

      expect(result, <String>['post1', 'post2', 'post3']);
      expect(result.toSet().length, result.length);
    });

    test('12. Rapid refresh stability', () async {
      for (var i = 0; i < 5; i++) {
        final result = await repo.getFeed();
        expect(result, isNotEmpty);
      }
    });

    test('13. Large data cache', () async {
      api.data = List<String>.generate(1000, (i) => 'post_$i');

      final result = await repo.getFeed();

      expect(result.length, 1000);
    });

    test('14. Cache survives multiple reads', () async {
      await repo.getFeed();
      api.shouldFail = true;

      final second = await repo.getFeed();

      expect(second, <String>['post1', 'post2']);
    });

    test('15. Cache not mutated externally', () async {
      final result = await repo.getFeed();
      result.add('hack');

      final cached = cache.get('feed') as List<String>;

      expect(cached.contains('hack'), isFalse);
    });
  });
}
