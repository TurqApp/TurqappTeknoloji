part of 'username_lookup_repository.dart';

extension UsernameLookupRepositoryFacadePart on UsernameLookupRepository {
  Future<String?> findUidForHandle(String handle) async {
    final normalized = normalizeNicknameInput(handle);
    if (normalized.isEmpty) return null;

    final cached = _cache[normalized];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <=
            UsernameLookupRepository._ttl) {
      return cached.uid;
    }

    String? uid;
    try {
      final usernameDoc =
          await _firestore.collection('usernames').doc(normalized).get();
      final mappedUid = (usernameDoc.data()?['uid'] ?? '').toString().trim();
      if (mappedUid.isNotEmpty) {
        uid = mappedUid;
      }
    } catch (_) {}

    if (uid == null) {
      try {
        final byUsername = await _firestore
            .collection('users')
            .where('username', isEqualTo: normalized)
            .limit(1)
            .get();
        if (byUsername.docs.isNotEmpty) {
          uid = byUsername.docs.first.id;
        }
      } catch (_) {}
    }

    if (uid == null) {
      try {
        final byNickname = await _firestore
            .collection('users')
            .where('nickname', isEqualTo: normalizeHandleInput(handle))
            .limit(1)
            .get();
        if (byNickname.docs.isNotEmpty) {
          uid = byNickname.docs.first.id;
        }
      } catch (_) {}
    }

    _cache[normalized] = _UsernameCacheEntry(
      uid: uid,
      cachedAt: DateTime.now(),
    );
    return uid;
  }
}
