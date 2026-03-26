part of 'follow_repository.dart';

extension FollowRepositoryQueryPart on FollowRepository {
  Future<List<String>> _fetchRelationPreviewIdsOnce(
    String uid, {
    required String relation,
    required int fetchLimit,
    required Source source,
  }) async {
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(relation);
    try {
      final snap = await query
          .orderBy('timeStamp', descending: true)
          .limit(fetchLimit)
          .get(GetOptions(source: source));
      return snap.docs.map((doc) => doc.id.trim()).toList(growable: false);
    } on FirebaseException {
      final snap =
          await query.limit(fetchLimit).get(GetOptions(source: source));
      return snap.docs.map((doc) => doc.id.trim()).toList(growable: false);
    }
  }

  Future<Set<String>> getFollowingIds(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    return getRelationIds(
      uid,
      relation: 'followings',
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
  }

  Future<Set<String>> getFollowerIds(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    return getRelationIds(
      uid,
      relation: 'followers',
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<String>> getFollowingPreviewIds(
    String uid, {
    int limit = ReadBudgetRegistry.followRelationPreviewInitialLimit,
    bool preferCache = true,
    bool forceRefresh = false,
  }) {
    return getRelationPreviewIds(
      uid,
      relation: 'followings',
      limit: limit,
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<String>> getFollowerPreviewIds(
    String uid, {
    int limit = ReadBudgetRegistry.followRelationPreviewInitialLimit,
    bool preferCache = true,
    bool forceRefresh = false,
  }) {
    return getRelationPreviewIds(
      uid,
      relation: 'followers',
      limit: limit,
      preferCache: preferCache,
      forceRefresh: forceRefresh,
    );
  }

  Future<List<String>> getRelationPreviewIds(
    String uid, {
    required String relation,
    int limit = ReadBudgetRegistry.followRelationPreviewInitialLimit,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return const <String>[];
    final fetchLimit = limit <= 0
        ? ReadBudgetRegistry.followRelationPreviewInitialLimit
        : limit;
    final initialSource = forceRefresh
        ? Source.server
        : (preferCache ? Source.serverAndCache : Source.server);
    final first = await _fetchRelationPreviewIdsOnce(
      uid,
      relation: relation,
      fetchLimit: fetchLimit,
      source: initialSource,
    );
    final normalizedFirst =
        first.where((id) => id.isNotEmpty).toSet().toList(growable: false);

    if (forceRefresh || !preferCache || normalizedFirst.length >= fetchLimit) {
      return normalizedFirst;
    }

    final refreshed = await _fetchRelationPreviewIdsOnce(
      uid,
      relation: relation,
      fetchLimit: fetchLimit,
      source: Source.server,
    );
    return refreshed
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<Set<String>> getRelationIds(
    String uid, {
    required String relation,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (uid.isEmpty) return <String>{};
    final relationKey = _relationKey(uid, relation);

    if (!forceRefresh) {
      final memory = _getRelationFromMemory(relationKey, allowStale: false);
      if (preferCache && memory != null) {
        return memory;
      }

      final disk = await _getRelationFromPrefs(relationKey, allowStale: false);
      if (preferCache && disk != null) {
        _relationMemory[relationKey] = _CachedFollowingSet(
          ids: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(relation)
        .get();
    final ids = snap.docs.map((doc) => doc.id).toSet();
    await _persistRelation(relationKey, ids);
    return ids;
  }

  Future<int> countFollowersInRange(
    String uid, {
    required int fromInclusive,
    int? toInclusive,
    int? toExclusive,
  }) async {
    if (uid.isEmpty) return 0;
    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('followers')
        .where('timeStamp', isGreaterThanOrEqualTo: fromInclusive);
    if (toInclusive != null) {
      query = query.where('timeStamp', isLessThanOrEqualTo: toInclusive);
    } else if (toExclusive != null) {
      query = query.where('timeStamp', isLessThan: toExclusive);
    }
    final aggregate = await query.count().get();
    return aggregate.count ?? 0;
  }

  Future<bool> isFollowing(
    String otherUid, {
    String? currentUid,
    bool preferCache = true,
  }) async {
    final me = currentUid ?? CurrentUserService.instance.effectiveUserId;
    if (me.isEmpty || otherUid.isEmpty) return false;

    if (preferCache) {
      final cached = await getFollowingIds(
        me,
        preferCache: true,
        forceRefresh: false,
      );
      if (cached.contains(otherUid)) return true;

      if (_hasFreshCache(me)) {
        return false;
      }
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(me)
        .collection('followings')
        .doc(otherUid)
        .get(GetOptions(
          source: preferCache ? Source.serverAndCache : Source.server,
        ));
    if (!doc.exists) return false;
    await applyToggle(
      me,
      otherUid,
      nowFollowing: true,
    );
    return true;
  }
}
