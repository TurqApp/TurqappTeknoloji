part of 'user_profile_cache_service.dart';

extension UserProfileCacheServiceFetchPart on UserProfileCacheService {
  CollectionReference<Map<String, dynamic>> get _usersPublicCollection =>
      AppFirestore.instance.collection('usersPublic');

  bool _isValidProfileUid(String uid) {
    final trimmed = uid.trim();
    return trimmed.isNotEmpty && !trimmed.contains('/');
  }

  Future<Map<String, dynamic>?> getProfile(
    String uid, {
    bool preferCache = true,
    bool cacheOnly = false,
    bool forceServer = false,
  }) async {
    if (uid.isEmpty) return null;
    final readDecision = MetadataReadPolicy.userProfileSummary(
      preferCache: preferCache,
      cacheOnly: cacheOnly,
      forceServer: forceServer,
    );

    if (!forceServer && preferCache) {
      final cached = _getFromMemory(
        uid,
        allowStale: readDecision.allowStaleRead,
      );
      if (cached != null) return cached;
    }

    if (cacheOnly) {
      final doc = await _usersPublicCollection
          .doc(uid)
          .get(const GetOptions(source: Source.cache));
      if (!doc.exists) {
        try {
          final legacyDoc = await AppFirestore.instance
              .collection('users')
              .doc(uid)
              .get(const GetOptions(source: Source.cache));
          if (legacyDoc.exists) {
            final map =
                _sanitizeProfile(legacyDoc.data() ?? const <String, dynamic>{});
            _put(uid, map);
            return map;
          }
        } catch (_) {}
        return _getFromMemory(uid, allowStale: readDecision.allowStaleRead);
      }
      final map = _sanitizeProfile(doc.data() ?? const <String, dynamic>{});
      _put(uid, map);
      return map;
    }

    if (!forceServer && preferCache) {
      try {
        final doc = await _usersPublicCollection
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        if (doc.exists) {
          final map = _sanitizeProfile(doc.data() ?? const <String, dynamic>{});
          _put(uid, map);
          return map;
        }
      } catch (_) {}
    }

    final server = await _usersPublicCollection.doc(uid).get();
    if (!server.exists) {
      try {
        final legacyServer =
            await AppFirestore.instance.collection('users').doc(uid).get();
        if (legacyServer.exists) {
          final map = _sanitizeProfile(
              legacyServer.data() ?? const <String, dynamic>{});
          _put(uid, map);
          return map;
        }
      } catch (_) {}
      return _getFromMemory(uid, allowStale: readDecision.allowStaleRead);
    }
    final map = _sanitizeProfile(server.data() ?? const <String, dynamic>{});
    _put(uid, map);
    return map;
  }

  Future<void> putProfile(String uid, Map<String, dynamic> profile) async {
    if (uid.isEmpty) return;
    _put(uid, _sanitizeProfile(profile));
  }

  Map<String, dynamic>? peekProfile(
    String uid, {
    bool allowStale = true,
  }) {
    if (uid.isEmpty) return null;
    return _getFromMemory(uid, allowStale: allowStale);
  }

  Future<Map<String, Map<String, dynamic>>> getProfiles(
    List<String> uids, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final out = <String, Map<String, dynamic>>{};
    final unique =
        uids.map((e) => e.trim()).where(_isValidProfileUid).toSet().toList();
    if (unique.isEmpty) return out;

    final missing = <String>[];
    for (final uid in unique) {
      if (preferCache) {
        final cached = _getFromMemory(uid, allowStale: true);
        if (cached != null) {
          out[uid] = cached;
          continue;
        }
      }
      missing.add(uid);
    }

    if (missing.isEmpty) return out;

    final fetched = await _fetchUsersChunked(
      missing,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    out.addAll(fetched);
    return out;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchUsersChunked(
    List<String> uids, {
    required bool preferCache,
    required bool cacheOnly,
  }) async {
    final result = <String, Map<String, dynamic>>{};
    const int chunkSize = 10;

    for (int i = 0; i < uids.length; i += chunkSize) {
      final chunk = uids.sublist(i, (i + chunkSize).clamp(0, uids.length));
      if (chunk.isEmpty) continue;

      if (preferCache) {
        try {
          final cacheSnap = await _usersPublicCollection
              .where(FieldPath.documentId, whereIn: chunk)
              .limit(chunk.length)
              .get(const GetOptions(source: Source.cache));
          for (final doc in cacheSnap.docs) {
            final map = _sanitizeProfile(doc.data());
            _put(doc.id, map);
            result[doc.id] = map;
          }
        } catch (_) {}
      }

      final unresolved =
          chunk.where((uid) => !result.containsKey(uid)).toList();
      if (unresolved.isEmpty || cacheOnly) continue;

      try {
        final serverSnap = await _usersPublicCollection
            .where(FieldPath.documentId, whereIn: unresolved)
            .limit(unresolved.length)
            .get();
        for (final doc in serverSnap.docs) {
          final map = _sanitizeProfile(doc.data());
          _put(doc.id, map);
          result[doc.id] = map;
        }
      } catch (_) {}

      final stillUnresolved =
          unresolved.where((uid) => !result.containsKey(uid)).toList();
      if (stillUnresolved.isEmpty || cacheOnly) continue;

      try {
        final legacySnap = await AppFirestore.instance
            .collection('users')
            .where(FieldPath.documentId, whereIn: stillUnresolved)
            .limit(stillUnresolved.length)
            .get();
        for (final doc in legacySnap.docs) {
          final map = _sanitizeProfile(doc.data());
          _put(doc.id, map);
          result[doc.id] = map;
        }
      } catch (_) {}
    }

    return result;
  }
}
