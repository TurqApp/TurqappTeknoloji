part of 'market_repository_library.dart';

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
    _memory[key] = _TimedMarketItems(
      items: _cloneItems(items),
      cachedAt: DateTime.now(),
    );
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
    return _cloneItems(cached.items);
  }

  Future<List<MarketItemModel>?> _getFromPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final prefs = _prefs;
    final dataKey = '${MarketRepository._prefsPrefix}::$key';
    final tsKey = '${MarketRepository._prefsPrefix}::$key::ts';
    final ts = prefs?.getInt(tsKey) ?? 0;
    if (ts <= 0) {
      await prefs?.remove(dataKey);
      await prefs?.remove(tsKey);
      return null;
    }
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > MarketRepository._ttl.inMilliseconds) {
      await prefs?.remove(dataKey);
      await prefs?.remove(tsKey);
      return null;
    }
    final raw = prefs?.getString(dataKey) ?? '';
    if (raw.isEmpty) {
      await prefs?.remove(dataKey);
      await prefs?.remove(tsKey);
      return null;
    }
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) {
        await prefs?.remove(dataKey);
        await prefs?.remove(tsKey);
        return null;
      }
      final list = decoded
          .map((e) => MarketItemModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
      return list;
    } catch (_) {
      await prefs?.remove(dataKey);
      await prefs?.remove(tsKey);
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

  List<MarketItemModel> _cloneItems(List<MarketItemModel> items) {
    return items.map(_cloneItem).toList(growable: false);
  }

  MarketItemModel _cloneItem(MarketItemModel item) {
    return MarketItemModel(
      id: item.id,
      userId: item.userId,
      title: item.title,
      description: item.description,
      price: item.price,
      currency: item.currency,
      categoryKey: item.categoryKey,
      categoryPath: List<String>.from(item.categoryPath),
      locationText: item.locationText,
      city: item.city,
      district: item.district,
      coverImageUrl: item.coverImageUrl,
      imageUrls: List<String>.from(item.imageUrls),
      sellerName: item.sellerName,
      sellerUsername: item.sellerUsername,
      sellerPhotoUrl: item.sellerPhotoUrl,
      sellerRozet: item.sellerRozet,
      shortId: item.shortId,
      shortUrl: item.shortUrl,
      sellerPhoneNumber: item.sellerPhoneNumber,
      showPhone: item.showPhone,
      contactPreference: item.contactPreference,
      status: item.status,
      createdAt: item.createdAt,
      favoriteCount: item.favoriteCount,
      offerCount: item.offerCount,
      viewCount: item.viewCount,
      isNegotiable: item.isNegotiable,
      attributes: Map<String, dynamic>.from(item.attributes),
    );
  }
}
