part of 'user_repository.dart';

extension UserRepositoryQueryPart on UserRepository {
  Future<bool> emailExists(
    String email, {
    bool preferCache = true,
  }) async {
    final normalized = normalizeEmailAddress(email);
    if (normalized.isEmpty) return false;
    final key = 'email::$normalized';
    final cached = _existsCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 10)) {
      return cached.value;
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();
    final exists = snap.docs.isNotEmpty;
    _existsCache[key] = _TimedUserLookup<bool>(
      value: exists,
      cachedAt: DateTime.now(),
    );
    return exists;
  }

  Future<bool> usernameLowerAvailable(
    String usernameLower, {
    bool preferCache = true,
  }) async {
    final normalized = normalizeNicknameInput(usernameLower);
    if (normalized.isEmpty) return false;
    final key = 'usernameLower::$normalized';
    final cached = _existsCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 10)) {
      return cached.value;
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('usernameLower', isEqualTo: normalized)
        .limit(1)
        .get();
    final available = snap.docs.isEmpty;
    _existsCache[key] = _TimedUserLookup<bool>(
      value: available,
      cachedAt: DateTime.now(),
    );
    return available;
  }

  Future<Map<String, dynamic>?> findUserByEmail(
    String email, {
    bool preferCache = true,
  }) async {
    final normalized = normalizeEmailAddress(email);
    if (normalized.isEmpty) return null;
    final key = 'findEmail::$normalized';
    final cached = _queryCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 10)) {
      return cached.value == null ? null : _cloneUserMap(cached.value!);
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: normalized)
        .limit(1)
        .get();
    Map<String, dynamic>? result;
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      result = <String, dynamic>{'id': doc.id, ...doc.data()};
      await _cache.putProfile(doc.id, doc.data());
    }
    _queryCache[key] = _TimedUserLookup<Map<String, dynamic>?>(
      value: result == null ? null : _cloneUserMap(result),
      cachedAt: DateTime.now(),
    );
    return result == null ? null : _cloneUserMap(result);
  }

  Future<String?> findUserIdByFcmToken(
    String token, {
    bool preferCache = true,
  }) async {
    final normalized = token.trim();
    if (normalized.isEmpty) return null;
    final key = 'findFcmToken::$normalized';
    final cached = _queryCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 10)) {
      return cached.value == null ? null : cached.value!['id']?.toString();
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('fcmToken', isEqualTo: normalized)
        .limit(1)
        .get();
    Map<String, dynamic>? result;
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      result = <String, dynamic>{'id': doc.id, ...doc.data()};
      await _cache.putProfile(doc.id, doc.data());
    }
    _queryCache[key] = _TimedUserLookup<Map<String, dynamic>?>(
      value: result == null ? null : _cloneUserMap(result),
      cachedAt: DateTime.now(),
    );
    return result == null ? null : result['id']?.toString();
  }

  Future<Map<String, dynamic>?> findUserByNickname(
    String nickname, {
    bool preferCache = true,
  }) async {
    final normalized = nickname.trim();
    if (normalized.isEmpty) return null;
    final key = 'findNickname::$normalized';
    final cached = _queryCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 10)) {
      return cached.value == null ? null : _cloneUserMap(cached.value!);
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isEqualTo: normalized)
        .limit(1)
        .get();
    Map<String, dynamic>? result;
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      result = <String, dynamic>{'id': doc.id, ...doc.data()};
      await _cache.putProfile(doc.id, doc.data());
    }
    _queryCache[key] = _TimedUserLookup<Map<String, dynamic>?>(
      value: result == null ? null : _cloneUserMap(result),
      cachedAt: DateTime.now(),
    );
    return result == null ? null : _cloneUserMap(result);
  }

  Future<Map<String, dynamic>?> findFirstByNicknamePrefix(
    String prefix, {
    bool preferCache = true,
  }) async {
    final normalized = normalizeNicknameInput(prefix);
    if (normalized.length < 2) return null;
    final key = 'nicknamePrefix::$normalized';
    final cached = _queryCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 5)) {
      return cached.value == null ? null : _cloneUserMap(cached.value!);
    }
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isGreaterThanOrEqualTo: normalized)
        .where('nickname', isLessThan: '$normalized\uf8ff')
        .limit(1)
        .get();
    Map<String, dynamic>? result;
    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      result = <String, dynamic>{'id': doc.id, ...doc.data()};
      await _cache.putProfile(doc.id, doc.data());
    }
    _queryCache[key] = _TimedUserLookup<Map<String, dynamic>?>(
      value: result == null ? null : _cloneUserMap(result),
      cachedAt: DateTime.now(),
    );
    return result == null ? null : _cloneUserMap(result);
  }

  Future<List<Map<String, dynamic>>> searchUsersByNicknamePrefix(
    String prefix, {
    int limit = 20,
    bool preferCache = true,
  }) async {
    final normalized = normalizeNicknameInput(prefix);
    if (normalized.length < 2) return const <Map<String, dynamic>>[];
    final key = 'nicknamePrefixList::$normalized::$limit';
    final cached = _queryCache[key];
    if (preferCache &&
        cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            const Duration(minutes: 5)) {
      final rawList = cached.value?['items'];
      if (rawList is List) {
        return rawList
            .whereType<Map>()
            .map((e) => _cloneUserMap(Map<String, dynamic>.from(e)))
            .toList(growable: false);
      }
      return const <Map<String, dynamic>>[];
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('nickname', isGreaterThanOrEqualTo: normalized)
        .where('nickname', isLessThan: '$normalized\uf8ff')
        .limit(limit)
        .get();

    final items = <Map<String, dynamic>>[];
    for (final doc in snap.docs) {
      final data = doc.data();
      await _cache.putProfile(doc.id, data);
      items.add(<String, dynamic>{'id': doc.id, ...data});
    }

    _queryCache[key] = _TimedUserLookup<Map<String, dynamic>?>(
      value: <String, dynamic>{
        'items': items,
      },
      cachedAt: DateTime.now(),
    );
    return items
        .map((entry) => _cloneUserMap(entry))
        .toList(growable: false);
  }

  Stream<Map<String, dynamic>?> watchUserRaw(String uid) {
    if (uid.isEmpty) return const Stream<Map<String, dynamic>?>.empty();
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      final data = Map<String, dynamic>.from(doc.data() ?? const {});
      final sanitized = Map<String, dynamic>.from(
        _cache.peekProfile(
              uid,
              allowStale: true,
            ) ??
            const <String, dynamic>{},
      )..addAll(data);
      unawaited(_cache.putProfile(uid, sanitized));
      return sanitized;
    });
  }

  Map<String, dynamic> _cloneUserMap(Map<String, dynamic> data) {
    return data.map((key, value) => MapEntry(key, _cloneUserValue(value)));
  }

  dynamic _cloneUserValue(dynamic value) {
    if (value is Map) {
      return value.map(
        (key, child) => MapEntry(key.toString(), _cloneUserValue(child)),
      );
    }
    if (value is List) {
      return value.map(_cloneUserValue).toList(growable: false);
    }
    return value;
  }
}
