part of 'market_repository.dart';

extension MarketRepositoryCachePart on MarketRepository {
  Future<QuerySnapshot<Map<String, dynamic>>> _fetchLatestSnapshot(
    int limit,
  ) async {
    const options = GetOptions(source: Source.serverAndCache);
    try {
      return await _itemsRef
          .where('status', isEqualTo: 'active')
          .orderBy('publishedAt', descending: true)
          .limit(limit)
          .get(options);
    } on FirebaseException {
      try {
        return await _itemsRef
            .where('status', isEqualTo: 'active')
            .orderBy('createdAt', descending: true)
            .limit(limit)
            .get(options);
      } on FirebaseException {
        return _itemsRef.limit(limit).get(options);
      }
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchOwnerSnapshot(
    String uid,
  ) async {
    const options = GetOptions(source: Source.serverAndCache);
    try {
      return await _itemsRef
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get(options);
    } on FirebaseException {
      return _itemsRef.where('userId', isEqualTo: uid).get(options);
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _fetchSavedRefs(
      String uid) async {
    const options = GetOptions(source: Source.serverAndCache);
    final ref =
        _firestore.collection('users').doc(uid).collection('savedMarket');
    try {
      return await ref
          .orderBy('createdAt', descending: true)
          .limit(ReadBudgetRegistry.savedMarketRefsInitialLimit)
          .get(options);
    } on FirebaseException {
      try {
        return await ref
            .orderBy('timeStamp', descending: true)
            .limit(ReadBudgetRegistry.savedMarketRefsInitialLimit)
            .get(options);
      } on FirebaseException {
        return ref
            .limit(ReadBudgetRegistry.savedMarketRefsInitialLimit)
            .get(options);
      }
    }
  }

  Future<void> _store(String key, List<MarketItemModel> items) async {
    _memory[key] = _TimedMarketItems(items: items, cachedAt: DateTime.now());
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '${MarketRepository._prefsPrefix}::$key',
      json.encode(items.map((item) => item.toJson()).toList(growable: false)),
    );
    await _prefs?.setInt(
      '${MarketRepository._prefsPrefix}::$key::ts',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  List<MarketItemModel>? _getFromMemory(String key) {
    final cached = _memory[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) > MarketRepository._ttl) {
      _memory.remove(key);
      return null;
    }
    return cached.items;
  }

  Future<List<MarketItemModel>?> _getFromPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final ts =
        _prefs?.getInt('${MarketRepository._prefsPrefix}::$key::ts') ?? 0;
    if (ts <= 0) return null;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > MarketRepository._ttl.inMilliseconds) return null;
    final raw =
        _prefs?.getString('${MarketRepository._prefsPrefix}::$key') ?? '';
    if (raw.isEmpty) return null;
    try {
      final list = (json.decode(raw) as List<dynamic>)
          .map((e) => MarketItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      return list;
    } catch (_) {
      return null;
    }
  }

  Iterable<List<String>> _chunkIds(List<String> ids, int size) sync* {
    for (var i = 0; i < ids.length; i += size) {
      final end = (i + size < ids.length) ? i + size : ids.length;
      yield ids.sublist(i, end);
    }
  }

  Future<void> _invalidateUserScopedCaches({
    required String userId,
    required String docId,
  }) async {
    final prefixes = <String>[
      'latest:',
      'owner:$userId',
      'saved:$userId',
      'doc:$docId',
    ];
    _memory.removeWhere(
      (key, _) => prefixes.any((prefix) => key.startsWith(prefix)),
    );
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    if (prefs == null) return;
    final keys = prefs.getKeys().where((key) {
      if (!key.startsWith('${MarketRepository._prefsPrefix}::')) return false;
      return prefixes.any(
        (prefix) => key.startsWith('${MarketRepository._prefsPrefix}::$prefix'),
      );
    });
    for (final key in keys.toList(growable: false)) {
      await prefs.remove(key);
    }
  }
}
