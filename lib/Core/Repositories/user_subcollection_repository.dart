import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserSubcollectionEntry {
  final String id;
  final Map<String, dynamic> data;

  const UserSubcollectionEntry({
    required this.id,
    required this.data,
  });
}

class _CachedUserSubcollection {
  final List<UserSubcollectionEntry> items;
  final DateTime cachedAt;

  const _CachedUserSubcollection({
    required this.items,
    required this.cachedAt,
  });
}

class UserSubcollectionRepository extends GetxService {
  static const Duration _ttl = Duration(hours: 6);
  static const String _prefsPrefix = 'user_subcollection_repository_v1';

  SharedPreferences? _prefs;
  final Map<String, _CachedUserSubcollection> _memory = {};

  static UserSubcollectionRepository ensure() {
    if (Get.isRegistered<UserSubcollectionRepository>()) {
      return Get.find<UserSubcollectionRepository>();
    }
    return Get.put(UserSubcollectionRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) {
      _prefs = prefs;
    });
  }

  Future<List<UserSubcollectionEntry>> getEntries(
    String uid, {
    required String subcollection,
    String? orderByField,
    bool descending = true,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    if (uid.isEmpty || subcollection.isEmpty) return const <UserSubcollectionEntry>[];
    final key = _cacheKey(uid, subcollection);

    if (!forceRefresh) {
      final memory = _getFromMemory(key, allowStale: false);
      if (preferCache && memory != null) return memory;
      final disk = await _getFromPrefs(key, allowStale: false);
      if (preferCache && disk != null) {
        _memory[key] = _CachedUserSubcollection(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
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

  Future<void> setEntries(
    String uid, {
    required String subcollection,
    required List<UserSubcollectionEntry> items,
  }) async {
    if (uid.isEmpty || subcollection.isEmpty) return;
    final key = _cacheKey(uid, subcollection);
    final cloned = items
        .map(
          (e) => UserSubcollectionEntry(
            id: e.id,
            data: Map<String, dynamic>.from(e.data),
          ),
        )
        .toList(growable: false);
    final cachedAt = DateTime.now();
    _memory[key] = _CachedUserSubcollection(items: cloned, cachedAt: cachedAt);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      _prefsKey(key),
      jsonEncode({
        't': cachedAt.millisecondsSinceEpoch,
        'items': cloned
            .map((e) => {'id': e.id, 'data': e.data})
            .toList(growable: false),
      }),
    );
  }

  Future<UserSubcollectionEntry?> getEntry(
    String uid, {
    required String subcollection,
    required String docId,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
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

  Future<void> invalidate(
    String uid, {
    required String subcollection,
  }) async {
    final key = _cacheKey(uid, subcollection);
    _memory.remove(key);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.remove(_prefsKey(key));
  }

  Future<void> upsertEntry(
    String uid, {
    required String subcollection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    if (uid.isEmpty || subcollection.isEmpty || docId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(subcollection)
        .doc(docId)
        .set(data, SetOptions(merge: true));

    final current = await getEntries(
      uid,
      subcollection: subcollection,
      preferCache: true,
      forceRefresh: false,
    );
    final next = List<UserSubcollectionEntry>.from(current)
      ..removeWhere((e) => e.id == docId)
      ..add(UserSubcollectionEntry(id: docId, data: Map<String, dynamic>.from(data)));
    await setEntries(uid, subcollection: subcollection, items: next);
  }

  Future<void> deleteEntry(
    String uid, {
    required String subcollection,
    required String docId,
  }) async {
    if (uid.isEmpty || subcollection.isEmpty || docId.isEmpty) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection(subcollection)
        .doc(docId)
        .delete();

    final current = await getEntries(
      uid,
      subcollection: subcollection,
      preferCache: true,
      forceRefresh: false,
    );
    final next =
        current.where((entry) => entry.id != docId).toList(growable: false);
    await setEntries(uid, subcollection: subcollection, items: next);
  }

  List<UserSubcollectionEntry>? _getFromMemory(
    String key, {
    required bool allowStale,
  }) {
    final entry = _memory[key];
    if (entry == null) return null;
    final fresh = DateTime.now().difference(entry.cachedAt) <= _ttl;
    if (!fresh && !allowStale) return null;
    return entry.items
        .map(
          (e) => UserSubcollectionEntry(
            id: e.id,
            data: Map<String, dynamic>.from(e.data),
          ),
        )
        .toList(growable: false);
  }

  Future<List<UserSubcollectionEntry>?> _getFromPrefs(
    String key, {
    required bool allowStale,
  }) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_prefsKey(key));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      final items =
          (decoded['items'] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      if (ts <= 0) return null;
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(ts);
      final fresh = DateTime.now().difference(cachedAt) <= _ttl;
      if (!fresh && !allowStale) return null;
      return items
          .map(
            (e) => UserSubcollectionEntry(
              id: (e['id'] ?? '').toString(),
              data: Map<String, dynamic>.from(
                (e['data'] as Map?)?.map((k, v) => MapEntry('$k', v)) ??
                    const <String, dynamic>{},
              ),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(String uid, String subcollection) => '$uid:$subcollection';

  String _prefsKey(String key) => '$_prefsPrefix:$key';
}
