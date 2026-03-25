part of 'user_subdoc_repository.dart';

extension UserSubdocRepositoryRuntimePart on UserSubdocRepository {
  void _handleUserSubdocRepositoryInit() {
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<Map<String, dynamic>> _getUserSubdocDoc(
    String uid, {
    required String collection,
    required String docId,
    required bool preferCache,
    required bool forceRefresh,
    required Duration ttl,
  }) async {
    if (uid.isEmpty || collection.isEmpty || docId.isEmpty) {
      return const <String, dynamic>{};
    }
    final key = _userSubdocCacheKey(uid, collection, docId);

    if (!forceRefresh && preferCache) {
      final memory = _getUserSubdocFromMemory(this, key, ttl: ttl);
      if (memory != null) return memory;

      final disk = await _getUserSubdocFromPrefs(this, key, ttl: ttl);
      if (disk != null) {
        _memory[key] = _CachedUserSubdoc(
          data: Map<String, dynamic>.from(disk),
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(collection)
        .doc(docId)
        .get();
    final data =
        Map<String, dynamic>.from(doc.data() ?? const <String, dynamic>{});
    await putDoc(
      uid,
      collection: collection,
      docId: docId,
      data: data,
    );
    return data;
  }

  Future<void> _setUserSubdocDoc(
    String uid, {
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
    required bool merge,
  }) async {
    if (uid.isEmpty || collection.isEmpty || docId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(collection)
        .doc(docId)
        .set(data, SetOptions(merge: merge));
    final current = await getDoc(
      uid,
      collection: collection,
      docId: docId,
      preferCache: true,
      forceRefresh: false,
    );
    final merged = merge
        ? (Map<String, dynamic>.from(current)..addAll(data))
        : Map<String, dynamic>.from(data);
    await putDoc(
      uid,
      collection: collection,
      docId: docId,
      data: merged,
    );
  }
}
