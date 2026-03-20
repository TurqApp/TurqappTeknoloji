import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

class BookletRepository extends GetxService {
  BookletRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'booklet_repository_v1';
  final Map<String, _TimedBooklets> _memory = <String, _TimedBooklets>{};
  SharedPreferences? _prefs;

  static BookletRepository ensure() {
    if (Get.isRegistered<BookletRepository>()) {
      return Get.find<BookletRepository>();
    }
    return Get.put(BookletRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<List<BookletModel>> fetchAll({
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _fetch(
        cacheKey: 'all',
        queryBuilder: () => _firestore.collection('books'),
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<List<BookletModel>> fetchByExamType(
    String sinavTuru, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _fetch(
        cacheKey: 'type:${normalizeSearchText(sinavTuru)}',
        queryBuilder: () => _firestore
            .collection('books')
            .where('sinavTuru', isEqualTo: sinavTuru),
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<List<BookletModel>> fetchByOwner(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) =>
      _fetch(
        cacheKey: 'owner:${normalizeSearchText(userId)}',
        queryBuilder: () =>
            _firestore.collection('books').where('userID', isEqualTo: userId),
        preferCache: preferCache,
        forceRefresh: forceRefresh,
        cacheOnly: cacheOnly,
      );

  Future<BookletPage> fetchPage({
    DocumentSnapshot? startAfter,
    int limit = 30,
    bool cacheOnly = false,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('books')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get(
      GetOptions(source: cacheOnly ? Source.cache : Source.serverAndCache),
    );
    final items = snap.docs
        .map((doc) => BookletModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    return BookletPage(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<List<BookletModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final ids =
        docIds.where((e) => e.trim().isNotEmpty).toList(growable: false);
    if (ids.isEmpty) return const <BookletModel>[];
    final byId = <String, BookletModel>{};
    const chunkSize = 10;
    for (var i = 0; i < ids.length; i += chunkSize) {
      final end = (i + chunkSize > ids.length) ? ids.length : i + chunkSize;
      final chunk = ids.sublist(i, end);
      for (final id in chunk) {
        if (preferCache) {
          final cached = await fetchById(id, preferCache: true);
          if (cached != null) {
            byId[id] = cached;
          }
        }
      }
      final missing = chunk.where((id) => !byId.containsKey(id)).toList();
      if (cacheOnly && missing.isNotEmpty) continue;
      if (missing.isEmpty) continue;
      final snap = await _firestore
          .collection('books')
          .where(FieldPath.documentId, whereIn: missing)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snap.docs) {
        final item = BookletModel.fromMap(doc.data(), doc.id);
        byId[doc.id] = item;
        await _store('doc:${doc.id}', <BookletModel>[item]);
      }
    }
    return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
  }

  Future<BookletModel?> fetchById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final key = 'doc:$docId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(key);
      if (memory != null && memory.isNotEmpty) return memory.first;
      final disk = await _getFromPrefs(key);
      if (disk != null && disk.isNotEmpty) {
        _memory[key] = _TimedBooklets(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk.first;
      }
    }

    if (cacheOnly) return null;

    final doc = await _firestore.collection('books').doc(docId).get();
    if (!doc.exists) return null;
    final item = BookletModel.fromMap(doc.data() ?? const {}, doc.id);
    await _store(key, <BookletModel>[item]);
    return item;
  }

  Future<List<Map<String, dynamic>>> fetchAnswerKeys(
    String bookletId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final key = 'answers:$bookletId';
    if (!forceRefresh && preferCache) {
      final cached = await _readRawList(key);
      if (cached != null) return cached;
    }

    final snap = await _firestore
        .collection('books')
        .doc(bookletId)
        .collection('CevapAnahtarlari')
        .get();
    final items = snap.docs
        .map((doc) => <String, dynamic>{
              'id': doc.id,
              'data': Map<String, dynamic>.from(doc.data()),
            })
        .toList(growable: false);
    await _storeRawList(key, items);
    return items;
  }

  Future<void> replaceAnswerKeys(
    String bookletId,
    List<Map<String, dynamic>> items,
  ) async {
    final ref = _firestore.collection('books').doc(bookletId);
    final answersRef = ref.collection('CevapAnahtarlari');
    final old = await fetchAnswerKeys(
      bookletId,
      preferCache: false,
      forceRefresh: true,
    );
    final batch = _firestore.batch();
    for (final answer in old) {
      final id = (answer['id'] ?? '').toString();
      if (id.isEmpty) continue;
      batch.delete(answersRef.doc(id));
    }
    final cachedItems = <Map<String, dynamic>>[];
    for (final item in items) {
      final data = Map<String, dynamic>.from(item);
      final docRef = answersRef.doc();
      batch.set(docRef, data);
      cachedItems.add(<String, dynamic>{
        'id': docRef.id,
        'data': data,
      });
    }
    await batch.commit();
    await _storeRawList(
      'answers:$bookletId',
      cachedItems,
    );
  }

  Future<List<BookletModel>> _fetch({
    required String cacheKey,
    required Query<Map<String, dynamic>> Function() queryBuilder,
    required bool preferCache,
    required bool forceRefresh,
    required bool cacheOnly,
  }) async {
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedBooklets(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    if (cacheOnly) return const <BookletModel>[];

    final snap = await queryBuilder().get();
    final items = snap.docs
        .map((doc) => BookletModel.fromMap(doc.data(), doc.id))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<void> _store(String cacheKey, List<BookletModel> items) async {
    final cloned = items.toList(growable: false);
    final now = DateTime.now();
    _memory[cacheKey] = _TimedBooklets(items: cloned, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$cacheKey',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'items': cloned
            .map((item) => <String, dynamic>{
                  'id': item.docID,
                  'd': <String, dynamic>{
                    'dil': item.dil,
                    'sinavTuru': item.sinavTuru,
                    'cover': item.cover,
                    'baslik': item.baslik,
                    'timeStamp': item.timeStamp,
                    'kaydet': item.kaydet,
                    'basimTarihi': item.basimTarihi,
                    'yayinEvi': item.yayinEvi,
                    'userID': item.userID,
                    'viewCount': item.viewCount,
                  },
                })
            .toList(growable: false),
      }),
    );
  }

  Future<void> _storeRawList(
    String cacheKey,
    List<Map<String, dynamic>> items,
  ) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$cacheKey',
      jsonEncode({
        't': DateTime.now().millisecondsSinceEpoch,
        'items': items,
      }),
    );
  }

  List<BookletModel>? _getFromMemory(String cacheKey) {
    final entry = _memory[cacheKey];
    if (entry == null) return null;
    final fresh = DateTime.now().difference(entry.cachedAt) <= _ttl;
    if (!fresh) return null;
    return entry.items.toList(growable: false);
  }

  Future<List<BookletModel>?> _getFromPrefs(String cacheKey) async {
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
          .map((e) => e as Map)
          .map(
            (e) => BookletModel.fromMap(
              Map<String, dynamic>.from((e['d'] as Map?) ?? const {}),
              (e['id'] ?? '').toString(),
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }

  Future<List<Map<String, dynamic>>?> _readRawList(String cacheKey) async {
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
      return ((decoded['items'] as List?) ?? const [])
          .map((e) => Map<String, dynamic>.from((e as Map)))
          .toList(growable: false);
    } catch (_) {
      return null;
    }
  }
}

class BookletPage {
  const BookletPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<BookletModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

class _TimedBooklets {
  const _TimedBooklets({
    required this.items,
    required this.cachedAt,
  });

  final List<BookletModel> items;
  final DateTime cachedAt;
}
