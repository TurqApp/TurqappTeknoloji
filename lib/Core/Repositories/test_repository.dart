import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/Education/test_readiness_model.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class TestRepository extends GetxService {
  TestRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'test_repository_v1';
  final Map<String, _TimedTests> _memory = <String, _TimedTests>{};
  SharedPreferences? _prefs;

  static TestRepository ensure() {
    if (Get.isRegistered<TestRepository>()) {
      return Get.find<TestRepository>();
    }
    return Get.put(TestRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<List<Map<String, dynamic>>> fetchAnswers(
    String testId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'answers:$testId';
    if (!forceRefresh && preferCache) {
      final cached = await _getRawList(cacheKey);
      if (cached != null) return cached;
    }

    final snap = await _firestore
        .collection('Testler')
        .doc(testId)
        .collection('Yanitlar')
        .get();
    final items = snap.docs
        .map((doc) => <String, dynamic>{
              '_docId': doc.id,
              ...doc.data(),
            })
        .toList(growable: false);
    await _storeRawList(cacheKey, items);
    return items;
  }

  Future<List<TestReadinessModel>> fetchQuestions(
    String testId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'questions:$testId';
    if (!forceRefresh && preferCache) {
      final cached = await _getRawList(cacheKey);
      if (cached != null) {
        return cached
            .map(_questionFromMap)
            .whereType<TestReadinessModel>()
            .toList(growable: false);
      }
    }

    final snap = await _firestore
        .collection('Testler')
        .doc(testId)
        .collection('Sorular')
        .orderBy('id', descending: false)
        .get();
    final items = snap.docs
        .map((doc) => <String, dynamic>{
              '_docId': doc.id,
              ...doc.data(),
            })
        .toList(growable: false);
    await _storeRawList(cacheKey, items);
    return items
        .map(_questionFromMap)
        .whereType<TestReadinessModel>()
        .toList(growable: false);
  }

  Future<void> submitAnswers(
    String testId, {
    required String userId,
    required List<String> answers,
  }) async {
    await _firestore
        .collection('Testler')
        .doc(testId)
        .collection('Yanitlar')
        .doc(DateTime.now().millisecondsSinceEpoch.toString())
        .set({
      'cevaplar': answers,
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'userID': userId,
    });
    _memory.remove('answers:$testId');
  }

  Future<List<TestsModel>> fetchByIds(
    List<String> ids, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final wanted = ids.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (wanted.isEmpty) return const <TestsModel>[];
    final resolved = <String, TestsModel>{};
    final missing = <String>[];

    if (preferCache) {
      for (final id in wanted) {
        final memory = _getFromMemory('doc:$id');
        if (memory != null && memory.isNotEmpty) {
          resolved[id] = memory.first;
          continue;
        }
        final disk = await _getTimedFromPrefs('doc:$id');
        if (disk != null && disk.items.isNotEmpty) {
          _memory['doc:$id'] = disk;
          resolved[id] = disk.items.first;
          continue;
        }
        missing.add(id);
      }
    } else {
      missing.addAll(wanted);
    }

    if (cacheOnly) {
      return wanted
          .map((id) => resolved[id])
          .whereType<TestsModel>()
          .toList(growable: false);
    }

    for (final chunk in _chunkIds(missing, 10)) {
      final snap = await _firestore
          .collection('Testler')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final item = _fromDoc(doc.id, doc.data());
        resolved[doc.id] = item;
        await _store('doc:${doc.id}', <TestsModel>[item]);
      }
    }

    return wanted
        .map((id) => resolved[id])
        .whereType<TestsModel>()
        .toList(growable: false);
  }

  Future<List<TestsModel>> fetchByOwner(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'owner:$userId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return disk.items;
      }
    }

    if (cacheOnly) return const <TestsModel>[];

    final snap = await _firestore
        .collection('Testler')
        .where('userID', isEqualTo: userId)
        .get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false)
      ..sort((a, b) => int.tryParse(b.timeStamp)?.compareTo(int.tryParse(a.timeStamp) ?? 0) ?? 0);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<TestsModel>> fetchAnsweredByUser(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'answered:$userId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return disk.items;
      }
    }

    if (cacheOnly) return const <TestsModel>[];

    final snap = await _firestore
        .collectionGroup('Yanitlar')
        .where('userID', isEqualTo: userId)
        .get();
    final testIds = <String>[];
    final seen = <String>{};
    for (final doc in snap.docs) {
      final parent = doc.reference.parent.parent;
      final testId = parent?.id ?? '';
      if (testId.isEmpty) continue;
      if (!seen.add(testId)) continue;
      testIds.add(testId);
    }

    final items = await fetchByIds(
      testIds,
      preferCache: preferCache,
      cacheOnly: cacheOnly,
    );
    items.sort((a, b) {
      final aTs = int.tryParse(a.timeStamp) ?? 0;
      final bTs = int.tryParse(b.timeStamp) ?? 0;
      return bTs.compareTo(aTs);
    });
    await _store(cacheKey, items);
    return items;
  }

  Future<List<TestsModel>> fetchFavorites(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'favorites:$userId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return disk.items;
      }
    }

    if (cacheOnly) return const <TestsModel>[];

    final snap = await _firestore
        .collection('Testler')
        .where('favoriler', arrayContains: userId)
        .get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<TestsModel>> fetchAll({
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    const cacheKey = 'all';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return disk.items;
      }
    }
    if (cacheOnly) return const <TestsModel>[];
    final snap = await _firestore.collection('Testler').get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<TestsModel>> fetchByType(
    String testTuru, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'type:${testTuru.trim().toLowerCase()}';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return disk.items;
      }
    }
    if (cacheOnly) return const <TestsModel>[];
    final snap = await _firestore
        .collection('Testler')
        .where('testTuru', isEqualTo: testTuru)
        .get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<TestPageResult> fetchSharedPage({
    DocumentSnapshot? startAfter,
    int limit = 30,
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final canUseCache = startAfter == null;
    final cacheKey = 'shared:first:$limit';
    if (canUseCache && !forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) {
        return TestPageResult(
          items: memory,
          lastDocument: null,
          hasMore: memory.length >= limit,
        );
      }
      final disk = await _getTimedFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = disk;
        return TestPageResult(
          items: disk.items,
          lastDocument: null,
          hasMore: disk.items.length >= limit,
        );
      }
    }
    if (canUseCache && cacheOnly) {
      return const TestPageResult(
        items: <TestsModel>[],
        lastDocument: null,
        hasMore: false,
      );
    }

    Query<Map<String, dynamic>> query = _firestore
        .collection('Testler')
        .where('paylasilabilir', isEqualTo: true)
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    if (canUseCache) {
      await _store(cacheKey, items);
    }
    return TestPageResult(
      items: items,
      lastDocument: snap.docs.isNotEmpty ? snap.docs.last : null,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<Map<String, dynamic>?> fetchRawById(
    String testId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'raw:$testId';
    if (!forceRefresh && preferCache) {
      final raw = await _getRawDoc(cacheKey);
      if (raw != null) return raw;
    }
    final doc = await _firestore.collection('Testler').doc(testId).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    await _storeRawDoc(cacheKey, data);
    return data;
  }

  Future<bool> toggleFavorite(
    String testId, {
    required String userId,
  }) async {
    final docRef = _firestore.collection('Testler').doc(testId);
    final docSnapshot = await docRef.get();
    if (!docSnapshot.exists) return false;

    final favorites =
        List<String>.from((docSnapshot.data()?['favoriler'] ?? const <String>[]));
    final isFavorite = favorites.contains(userId);
    await docRef.update({
      'favoriler': isFavorite
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });

    final updated = Map<String, dynamic>.from(docSnapshot.data() ?? const {})
      ..['favoriler'] = isFavorite
          ? favorites.where((e) => e != userId).toList(growable: false)
          : <String>[...favorites, userId];
    await _storeRawDoc('raw:$testId', updated);
    return !isFavorite;
  }

  TestsModel _fromDoc(String id, Map<String, dynamic> data) {
    return TestsModel(
      userID: (data['userID'] ?? '').toString(),
      timeStamp: (data['timeStamp'] ?? '').toString(),
      aciklama: (data['aciklama'] ?? '').toString(),
      dersler: (data['dersler'] is List)
          ? (data['dersler'] as List).map((e) => e.toString()).toList()
          : <String>[],
      img: (data['img'] ?? '').toString(),
      docID: id,
      paylasilabilir: data['paylasilabilir'] == true,
      testTuru: (data['testTuru'] ?? '').toString(),
      taslak: data['taslak'] == true,
    );
  }

  Future<void> _store(String cacheKey, List<TestsModel> items) async {
    final cloned = items.toList(growable: false);
    final now = DateTime.now();
    _memory[cacheKey] = _TimedTests(items: cloned, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$cacheKey',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'items': cloned
            .map((item) => <String, dynamic>{
                  'id': item.docID,
                  'd': <String, dynamic>{
                    'userID': item.userID,
                    'timeStamp': item.timeStamp,
                    'aciklama': item.aciklama,
                    'dersler': item.dersler,
                    'img': item.img,
                    'paylasilabilir': item.paylasilabilir,
                    'testTuru': item.testTuru,
                    'taslak': item.taslak,
                  },
                })
            .toList(growable: false),
      }),
    );
  }

  Future<void> _storeRawDoc(String cacheKey, Map<String, dynamic> data) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'data': data,
      }),
    );
  }

  Future<void> _storeRawList(
    String cacheKey,
    List<Map<String, dynamic>> data,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'items': data,
      }),
    );
  }

  Future<List<Map<String, dynamic>>?> _getRawList(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix:$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              _ttl;
      if (!fresh) return null;
      final items = (decoded['items'] as List?) ?? const [];
      return items
          .map((item) => Map<String, dynamic>.from((item as Map?) ?? const {}))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _getRawDoc(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix:$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              _ttl;
      if (!fresh) return null;
      return Map<String, dynamic>.from(
        (decoded['data'] as Map?) ?? const <String, dynamic>{},
      );
    } catch (_) {
      return null;
    }
  }

  List<TestsModel>? _getFromMemory(String cacheKey) {
    final entry = _memory[cacheKey];
    if (entry == null) return null;
    final fresh = DateTime.now().difference(entry.cachedAt) <= _ttl;
    if (!fresh) return null;
    return entry.items.toList(growable: false);
  }

  Future<_TimedTests?> _getTimedFromPrefs(String cacheKey) async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs?.getString('$_prefsPrefix:$cacheKey');
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final ts = (decoded['t'] as num?)?.toInt() ?? 0;
      if (ts <= 0) return null;
      final fresh =
          DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ts)) <=
              _ttl;
      if (!fresh) return null;
      final items = (decoded['items'] as List?) ?? const [];
      return _TimedTests(
        items: items
            .map((e) => e as Map)
            .map(
              (e) => _fromDoc(
                (e['id'] ?? '').toString(),
                Map<String, dynamic>.from((e['d'] as Map?) ?? const {}),
              ),
            )
            .toList(growable: false),
        cachedAt: DateTime.fromMillisecondsSinceEpoch(ts),
      );
    } catch (_) {
      return null;
    }
  }

  List<List<String>> _chunkIds(List<String> ids, int size) {
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += size) {
      final end = (i + size < ids.length) ? i + size : ids.length;
      chunks.add(ids.sublist(i, end));
    }
    return chunks;
  }

  TestReadinessModel? _questionFromMap(Map<String, dynamic> raw) {
    final docId = (raw['_docId'] ?? '').toString();
    if (docId.isEmpty) return null;
    final id = raw['id'] is num
        ? raw['id'] as num
        : num.tryParse((raw['id'] ?? '0').toString()) ?? 0;
    return TestReadinessModel(
      id: id,
      img: (raw['img'] ?? '').toString(),
      max: (raw['max'] ?? 0) as num,
      dogruCevap: (raw['dogruCevap'] ?? '').toString(),
      docID: docId,
    );
  }
}

class _TimedTests {
  const _TimedTests({
    required this.items,
    required this.cachedAt,
  });

  final List<TestsModel> items;
  final DateTime cachedAt;
}

class TestPageResult {
  const TestPageResult({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<TestsModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}
