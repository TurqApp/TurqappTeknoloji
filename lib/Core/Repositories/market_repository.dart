import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';

part 'market_repository_query_part.dart';
part 'market_repository_action_part.dart';

class MarketRepository extends GetxService {
  MarketRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 3);
  static const String _prefsPrefix = 'market_repository_v1';
  final Map<String, _TimedMarketItems> _memory = <String, _TimedMarketItems>{};
  SharedPreferences? _prefs;

  static MarketRepository? maybeFind() {
    final isRegistered = Get.isRegistered<MarketRepository>();
    if (!isRegistered) return null;
    return Get.find<MarketRepository>();
  }

  static MarketRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(MarketRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _firestore.collection('marketStore');

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
