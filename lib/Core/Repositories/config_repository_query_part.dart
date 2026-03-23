part of 'config_repository.dart';

extension ConfigRepositoryQueryPart on ConfigRepository {
  Future<Map<String, dynamic>?> _getAdminConfigDocImpl(
    String docId, {
    required bool preferCache,
    required bool forceRefresh,
    required Duration ttl,
  }) async {
    if (docId.isEmpty) return null;
    final key = _docKeyImpl(docId);

    if (!forceRefresh && preferCache) {
      final memory = _getFromMemoryImpl(key, ttl: ttl);
      if (memory != null) return memory;

      final disk = await _getFromPrefsImpl(key, ttl: ttl);
      if (disk != null) {
        _memory[key] = _CachedConfigDoc(
          data: Map<String, dynamic>.from(disk),
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final doc = await FirebaseFirestore.instance
        .collection('adminConfig')
        .doc(docId)
        .get();
    if (!doc.exists) return null;
    final data =
        Map<String, dynamic>.from(doc.data() ?? const <String, dynamic>{});
    await putAdminConfigDoc(docId, data);
    return data;
  }

  Stream<Map<String, dynamic>> _watchAdminConfigDocImpl(
    String docId, {
    required Duration ttl,
  }) async* {
    if (docId.isEmpty) {
      yield const <String, dynamic>{};
      return;
    }

    final cached = await getAdminConfigDoc(
      docId,
      preferCache: true,
      forceRefresh: false,
      ttl: ttl,
    );
    if (cached != null) {
      yield Map<String, dynamic>.from(cached);
    }

    yield* FirebaseFirestore.instance
        .collection('adminConfig')
        .doc(docId)
        .snapshots()
        .asyncMap((doc) async {
      final data = Map<String, dynamic>.from(
        doc.data() ?? const <String, dynamic>{},
      );
      if (data.isNotEmpty) {
        await putAdminConfigDoc(docId, data);
      }
      return data;
    });
  }

  Future<Map<String, dynamic>?> _getLegacyConfigDocImpl({
    required String collection,
    required String docId,
    required bool preferCache,
    required bool forceRefresh,
    required Duration ttl,
  }) async {
    if (collection.isEmpty || docId.isEmpty) return null;
    final key = _legacyDocKeyImpl(collection, docId);

    if (!forceRefresh && preferCache) {
      final memory = _getFromMemoryImpl(key, ttl: ttl);
      if (memory != null) return memory;

      final disk = await _getFromPrefsImpl(key, ttl: ttl);
      if (disk != null) {
        _memory[key] = _CachedConfigDoc(
          data: Map<String, dynamic>.from(disk),
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final doc = await FirebaseFirestore.instance
        .collection(collection)
        .doc(docId)
        .get();
    if (!doc.exists) return null;
    final data =
        Map<String, dynamic>.from(doc.data() ?? const <String, dynamic>{});
    await _putLegacyConfigDocImpl(
      collection: collection,
      docId: docId,
      data: data,
    );
    return data;
  }
}
