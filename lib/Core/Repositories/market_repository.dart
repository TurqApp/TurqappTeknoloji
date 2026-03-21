import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';

class MarketRepository extends GetxService {
  MarketRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 3);
  static const String _prefsPrefix = 'market_repository_v1';
  final Map<String, _TimedMarketItems> _memory = <String, _TimedMarketItems>{};
  SharedPreferences? _prefs;

  static MarketRepository _ensureService() {
    if (Get.isRegistered<MarketRepository>()) {
      return Get.find<MarketRepository>();
    }
    return Get.put(MarketRepository(), permanent: true);
  }

  static MarketRepository ensure() {
    return _ensureService();
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _firestore.collection('marketStore');

  Future<List<MarketItemModel>> fetchLatestItems({
    int limit = 24,
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'latest:$limit';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedMarketItems(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final snapshot = await _fetchLatestSnapshot(limit);
    final items = snapshot.docs
        .map((doc) => MarketItemModel.fromMap(doc.data(), doc.id))
        .where((item) => item.status == 'active')
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<MarketItemModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'doc:$docId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null && memory.isNotEmpty) return memory.first;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null && disk.isNotEmpty) {
        _memory[cacheKey] = _TimedMarketItems(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk.first;
      }
    }

    final doc = await _itemsRef.doc(docId).get(
          const GetOptions(source: Source.serverAndCache),
        );
    if (!doc.exists) return null;
    final item = MarketItemModel.fromMap(doc.data() ?? const {}, doc.id);
    await _store(cacheKey, <MarketItemModel>[item]);
    return item;
  }

  Future<List<MarketItemModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
  }) async {
    final ids = docIds.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <MarketItemModel>[];

    final resolved = <String, MarketItemModel>{};
    final missing = <String>[];

    if (preferCache) {
      for (final id in ids) {
        final memory = _getFromMemory('doc:$id');
        if (memory != null && memory.isNotEmpty) {
          resolved[id] = memory.first;
          continue;
        }
        final disk = await _getFromPrefs('doc:$id');
        if (disk != null && disk.isNotEmpty) {
          _memory['doc:$id'] = _TimedMarketItems(
            items: disk,
            cachedAt: DateTime.now(),
          );
          resolved[id] = disk.first;
          continue;
        }
        missing.add(id);
      }
    } else {
      missing.addAll(ids);
    }

    for (final chunk in _chunkIds(missing, 10)) {
      final snap = await _itemsRef
          .where(FieldPath.documentId, whereIn: chunk)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snap.docs) {
        final item = MarketItemModel.fromMap(doc.data(), doc.id);
        resolved[doc.id] = item;
        await _store('doc:${doc.id}', <MarketItemModel>[item]);
      }
    }

    return ids
        .map((id) => resolved[id])
        .whereType<MarketItemModel>()
        .toList(growable: false);
  }

  Future<List<MarketItemModel>> fetchByOwner(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (uid.trim().isEmpty) return const <MarketItemModel>[];
    final cacheKey = 'owner:$uid';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedMarketItems(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final snapshot = await _fetchOwnerSnapshot(uid);
    final items = snapshot.docs
        .map((doc) => MarketItemModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<MarketItemModel>> fetchSaved(
    String uid, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    if (uid.trim().isEmpty) return const <MarketItemModel>[];
    final cacheKey = 'saved:$uid';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedMarketItems(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final snapshot = await _fetchSavedRefs(uid);
    final ids = snapshot.docs
        .map((doc) => (doc.data()['itemId'] ?? doc.id).toString())
        .where((id) => id.trim().isNotEmpty)
        .toList(growable: false);
    final items = await fetchByIds(ids, preferCache: preferCache);
    final byId = <String, MarketItemModel>{
      for (final item in items) item.id: item,
    };
    final ordered = ids
        .map((id) => byId[id])
        .whereType<MarketItemModel>()
        .toList(growable: false);
    await _store(cacheKey, ordered);
    return ordered;
  }

  Future<void> saveItem({
    required String docId,
    required Map<String, dynamic> payload,
    required String userId,
  }) async {
    await _itemsRef.doc(docId).set(payload, SetOptions(merge: true));
    await _invalidateUserScopedCaches(userId: userId, docId: docId);
    await TypesenseMarketSearchService.instance.invalidateForMutation(
      docId: docId,
      userId: userId,
    );
  }

  Future<void> updateItemStatus({
    required String docId,
    required String userId,
    required String status,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _itemsRef.doc(docId).set({
      'status': status,
      'updatedAt': now,
      if (status == 'sold') 'soldAt': now,
      if (status == 'active') 'publishedAt': now,
    }, SetOptions(merge: true));
    await _invalidateUserScopedCaches(userId: userId, docId: docId);
    await TypesenseMarketSearchService.instance.invalidateForMutation(
      docId: docId,
      userId: userId,
    );
  }

  Future<void> invalidateItemCaches({
    required String userId,
    required String docId,
  }) async {
    await _invalidateUserScopedCaches(userId: userId, docId: docId);
    await TypesenseMarketSearchService.instance.invalidateForMutation(
      docId: docId,
      userId: userId,
    );
  }

  Future<void> incrementViewCount({
    required String docId,
    required String userId,
  }) async {
    await _itemsRef.doc(docId).set({
      'viewCount': FieldValue.increment(1),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
    await _invalidateUserScopedCaches(userId: userId, docId: docId);
    await TypesenseMarketSearchService.instance.invalidateForMutation(
      docId: docId,
      userId: userId,
    );
  }

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
          .limit(50)
          .get(options);
    } on FirebaseException {
      try {
        return await ref
            .orderBy('timeStamp', descending: true)
            .limit(50)
            .get(options);
      } on FirebaseException {
        return ref.limit(50).get(options);
      }
    }
  }

  Future<void> _store(String key, List<MarketItemModel> items) async {
    _memory[key] = _TimedMarketItems(items: items, cachedAt: DateTime.now());
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix::$key',
      json.encode(items.map((item) => item.toJson()).toList(growable: false)),
    );
    await _prefs?.setInt(
      '$_prefsPrefix::$key::ts',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  List<MarketItemModel>? _getFromMemory(String key) {
    final cached = _memory[key];
    if (cached == null) return null;
    if (DateTime.now().difference(cached.cachedAt) > _ttl) {
      _memory.remove(key);
      return null;
    }
    return cached.items;
  }

  Future<List<MarketItemModel>?> _getFromPrefs(String key) async {
    _prefs ??= await SharedPreferences.getInstance();
    final ts = _prefs?.getInt('$_prefsPrefix::$key::ts') ?? 0;
    if (ts <= 0) return null;
    final age = DateTime.now().millisecondsSinceEpoch - ts;
    if (age > _ttl.inMilliseconds) return null;
    final raw = _prefs?.getString('$_prefsPrefix::$key') ?? '';
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
      if (!key.startsWith('$_prefsPrefix::')) return false;
      return prefixes.any((prefix) => key.startsWith('$_prefsPrefix::$prefix'));
    });
    for (final key in keys.toList(growable: false)) {
      await prefs.remove(key);
    }
  }
}

class _TimedMarketItems {
  _TimedMarketItems({
    required this.items,
    required this.cachedAt,
  });

  final List<MarketItemModel> items;
  final DateTime cachedAt;
}
