part of 'user_subcollection_repository.dart';

extension UserSubcollectionRepositoryQueryPart on UserSubcollectionRepository {
  Future<List<UserSubcollectionEntry>> _getEntriesImpl(
    String uid, {
    required String subcollection,
    required String? orderByField,
    required int? limit,
    required bool descending,
    required bool preferCache,
    required bool forceRefresh,
    required bool cacheOnly,
  }) async {
    if (uid.isEmpty || subcollection.isEmpty) {
      return const <UserSubcollectionEntry>[];
    }
    final key = _cacheKeyImpl(uid, subcollection);

    if (!forceRefresh) {
      final memory = _getFromMemoryImpl(key, allowStale: false);
      if (preferCache && memory != null) {
        if (limit == null || limit <= 0 || memory.length <= limit) {
          return memory;
        }
        return memory.take(limit).toList(growable: false);
      }
      final disk = await _getFromPrefsImpl(key, allowStale: false);
      if (preferCache && disk != null) {
        final cloned = _cloneEntriesImpl(disk);
        _memory[key] = _CachedUserSubcollection(
          items: cloned,
          cachedAt: DateTime.now(),
        );
        if (limit == null || limit <= 0 || cloned.length <= limit) {
          return _cloneEntriesImpl(cloned);
        }
        return _cloneEntriesImpl(
          cloned.take(limit).toList(growable: false),
        );
      }
    }

    if (cacheOnly) return const <UserSubcollectionEntry>[];

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(subcollection);
    if (orderByField != null && orderByField.trim().isNotEmpty) {
      query = query.orderBy(orderByField, descending: descending);
    }
    if (limit != null && limit > 0) {
      query = query.limit(limit);
    }
    final snap = await query.get();
    final items = snap.docs
        .map(
          (doc) => UserSubcollectionEntry(
            id: doc.id,
            data: Map<String, dynamic>.from(doc.data()),
          ),
        )
        .toList(growable: false);
    await setEntries(uid, subcollection: subcollection, items: items);
    return items;
  }

  Future<UserSubcollectionEntry?> _getEntryImpl(
    String uid, {
    required String subcollection,
    required String docId,
    required bool preferCache,
    required bool forceRefresh,
    required bool cacheOnly,
  }) async {
    if (uid.isEmpty || subcollection.isEmpty || docId.isEmpty) return null;
    if (!forceRefresh && preferCache) {
      final cached = await getEntries(
        uid,
        subcollection: subcollection,
        preferCache: true,
        forceRefresh: false,
        cacheOnly: cacheOnly,
      );
      for (final entry in cached) {
        if (entry.id == docId) return entry;
      }
    }

    if (cacheOnly) return null;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(subcollection)
        .doc(docId)
        .get();
    if (!doc.exists) return null;

    final entry = UserSubcollectionEntry(
      id: doc.id,
      data: Map<String, dynamic>.from(doc.data() ?? const <String, dynamic>{}),
    );

    final current = await getEntries(
      uid,
      subcollection: subcollection,
      preferCache: true,
      forceRefresh: false,
    );
    final next = List<UserSubcollectionEntry>.from(current)
      ..removeWhere((e) => e.id == docId)
      ..add(entry);
    await setEntries(uid, subcollection: subcollection, items: next);
    return entry;
  }
}
