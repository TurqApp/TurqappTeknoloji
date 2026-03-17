import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/ders_ve_sonuclar_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

class PracticeExamRepository extends GetxService {
  PracticeExamRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'practice_exam_repository_v1';
  final Map<String, _TimedPracticeExams> _memory =
      <String, _TimedPracticeExams>{};
  final Map<String, _TimedPracticeExamBool> _boolMemory =
      <String, _TimedPracticeExamBool>{};
  SharedPreferences? _prefs;

  static PracticeExamRepository ensure() {
    if (Get.isRegistered<PracticeExamRepository>()) {
      return Get.find<PracticeExamRepository>();
    }
    return Get.put(PracticeExamRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<List<SinavModel>> fetchByExamType(
    String sinavTuru, {
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final cacheKey = 'type:${sinavTuru.trim().toLowerCase()}';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedPracticeExams(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    if (cacheOnly) return const <SinavModel>[];

    final snap = await _firestore
        .collection('practiceExams')
        .where('sinavTuru', isEqualTo: sinavTuru)
        .get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<SinavModel>> fetchAll({
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'all';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedPracticeExams(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final snap = await _firestore
        .collection('practiceExams')
        .orderBy('timeStamp', descending: true)
        .get();
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, items);
    return items;
  }

  Future<List<SinavModel>> fetchByOwner(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return const <SinavModel>[];
    final cacheKey = 'owner:$normalizedUserId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedPracticeExams(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final snap = await _firestore
        .collection('practiceExams')
        .where('userID', isEqualTo: normalizedUserId)
        .get();
    final items = snap.docs
      ..sort((a, b) {
        final aTs = (a.data()['timeStamp'] as num?) ?? 0;
        final bTs = (b.data()['timeStamp'] as num?) ?? 0;
        return bTs.compareTo(aTs);
      });
    final models = items
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    await _store(cacheKey, models);
    return models;
  }

  Future<PracticeExamPage> fetchPage({
    DocumentSnapshot? startAfter,
    int limit = 30,
    bool cacheOnly = false,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('practiceExams')
        .orderBy('timeStamp', descending: true)
        .limit(limit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await query.get(
      GetOptions(source: cacheOnly ? Source.cache : Source.serverAndCache),
    );
    final items = snap.docs
        .map((doc) => _fromDoc(doc.id, doc.data()))
        .toList(growable: false);
    return PracticeExamPage(
      items: items,
      lastDocument: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= limit,
    );
  }

  Future<SinavModel?> fetchById(
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
        _memory[cacheKey] = _TimedPracticeExams(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk.first;
      }
    }

    final doc = await _firestore.collection('practiceExams').doc(docId).get();
    if (!doc.exists) return null;
    final item = _fromDoc(doc.id, doc.data() ?? const {});
    await _store(cacheKey, <SinavModel>[item]);
    return item;
  }

  Future<Map<String, dynamic>?> fetchRawById(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'raw:$docId';
    if (!forceRefresh && preferCache) {
      final raw = await _getRawDoc(cacheKey);
      if (raw != null) return raw;
    }

    final doc = await _firestore.collection('practiceExams').doc(docId).get();
    if (!doc.exists) return null;
    final data = Map<String, dynamic>.from(doc.data() ?? const {});
    await _storeRawDoc(cacheKey, data);
    return data;
  }

  Future<List<SinavModel>> fetchByIds(
    List<String> docIds, {
    bool preferCache = true,
  }) async {
    final ids = docIds.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (ids.isEmpty) return const <SinavModel>[];

    final resolved = <String, SinavModel>{};
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
          _memory['doc:$id'] = _TimedPracticeExams(
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
      final snap = await _firestore
          .collection('practiceExams')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snap.docs) {
        final item = _fromDoc(doc.id, doc.data());
        resolved[doc.id] = item;
        await _store('doc:${doc.id}', <SinavModel>[item]);
      }
    }

    return ids
        .map((id) => resolved[id])
        .whereType<SinavModel>()
        .toList(growable: false);
  }

  Future<List<SinavModel>> fetchAnsweredByUser(
    String userId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final normalizedUserId = userId.trim();
    if (normalizedUserId.isEmpty) return const <SinavModel>[];
    final cacheKey = 'answered:$normalizedUserId';
    if (!forceRefresh && preferCache) {
      final memory = _getFromMemory(cacheKey);
      if (memory != null) return memory;
      final disk = await _getFromPrefs(cacheKey);
      if (disk != null) {
        _memory[cacheKey] = _TimedPracticeExams(
          items: disk,
          cachedAt: DateTime.now(),
        );
        return disk;
      }
    }

    final yanitlarSnap = await _firestore
        .collectionGroup('Yanitlar')
        .where('userID', isEqualTo: normalizedUserId)
        .get();

    final examDocIds = <String>{};
    for (final yanitDoc in yanitlarSnap.docs) {
      final parentRef = yanitDoc.reference.parent.parent;
      if (parentRef != null && parentRef.parent.id == 'practiceExams') {
        examDocIds.add(parentRef.id);
      }
    }

    if (examDocIds.isEmpty) {
      await _store(cacheKey, const <SinavModel>[]);
      return const <SinavModel>[];
    }

    final models = await fetchByIds(
      examDocIds.toList(growable: false),
      preferCache: preferCache,
    );
    final sorted = models.toList(growable: false)
      ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    await _store(cacheKey, sorted);
    return sorted;
  }

  Future<bool> hasApplication(
    String examId,
    String userId,
  ) async {
    final normalizedExamId = examId.trim();
    final normalizedUserId = userId.trim();
    if (normalizedExamId.isEmpty || normalizedUserId.isEmpty) return false;
    final cacheKey = 'application:$normalizedExamId:$normalizedUserId';
    final cached = _boolMemory[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.cachedAt) <= _ttl) {
      return cached.value;
    }

    final snap = await _firestore
        .collection('practiceExams')
        .doc(normalizedExamId)
        .collection('Basvurular')
        .doc(normalizedUserId)
        .get(const GetOptions(source: Source.serverAndCache));
    _boolMemory[cacheKey] = _TimedPracticeExamBool(
      value: snap.exists,
      cachedAt: DateTime.now(),
    );
    return snap.exists;
  }

  Future<int> fetchParticipantCount(
    String docId, {
    bool preferCache = true,
  }) async {
    final raw = await fetchRawById(docId, preferCache: preferCache);
    final participantCount = raw?['participantCount'];
    if (participantCount is num) {
      return participantCount.toInt();
    }
    final aggregate = await _firestore
        .collection('practiceExams')
        .doc(docId)
        .collection('Basvurular')
        .count()
        .get();
    return aggregate.count ?? 0;
  }

  Future<List<Map<String, dynamic>>> fetchAnswers(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'answers:$docId';
    if (!forceRefresh && preferCache) {
      final cached = await _getRawList(cacheKey);
      if (cached != null) return cached;
    }

    final snap = await _firestore
        .collection('practiceExams')
        .doc(docId)
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

  Future<List<SoruModel>> fetchQuestions(
    String docId, {
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'questions:$docId';
    if (!forceRefresh && preferCache) {
      final cached = await _getRawList(cacheKey);
      if (cached != null) {
        return cached
            .map(_questionFromMap)
            .whereType<SoruModel>()
            .toList(growable: false);
      }
    }

    final snap = await _firestore
        .collection('practiceExams')
        .doc(docId)
        .collection('Sorular')
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
        .whereType<SoruModel>()
        .toList(growable: false);
  }

  Future<List<DersVeSonuclarDB>> fetchLessonResults(
    String examId,
    String answerId,
    List<String> lessons,
  ) async {
    final results = <DersVeSonuclarDB>[];
    for (final lesson in lessons) {
      final cacheKey = 'lesson_result:$examId:$answerId:$lesson';
      Map<String, dynamic>? data = await _getRawDoc(cacheKey);
      if (data == null) {
        final doc = await _firestore
            .collection('practiceExams')
            .doc(examId)
            .collection('Yanitlar')
            .doc(answerId)
            .collection(lesson)
            .doc(answerId)
            .get();
        if (!doc.exists) continue;
        data = Map<String, dynamic>.from(doc.data() ?? const {});
        await _storeRawDoc(cacheKey, data);
      }
      results.add(
        DersVeSonuclarDB(
          ders: (data['ders'] ?? lesson).toString(),
          dogru: (data['dogru'] ?? 0) as num,
          yanlis: (data['yanlis'] ?? 0) as num,
          bos: (data['bos'] ?? 0) as num,
          net: (data['net'] ?? 0) as num,
        ),
      );
    }
    return results;
  }

  SinavModel _fromDoc(String docId, Map<String, dynamic> data) {
    return SinavModel(
      docID: docId,
      cover: (data['cover'] ?? '').toString(),
      sinavTuru: (data['sinavTuru'] ?? '').toString(),
      timeStamp: data['timeStamp'] is num
          ? data['timeStamp'] as num
          : num.tryParse((data['timeStamp'] ?? '0').toString()) ?? 0,
      sinavAciklama: (data['sinavAciklama'] ?? '').toString(),
      sinavAdi: (data['sinavAdi'] ?? '').toString(),
      kpssSecilenLisans: (data['kpssSecilenLisans'] ?? '').toString(),
      dersler: (data['dersler'] is List)
          ? (data['dersler'] as List).map((e) => e.toString()).toList()
          : <String>[],
      taslak: data['taslak'] == true,
      public: data['public'] != false,
      userID: (data['userID'] ?? '').toString(),
      soruSayilari: (data['soruSayilari'] is List)
          ? (data['soruSayilari'] as List).map((e) => e.toString()).toList()
          : <String>[],
      bitis: data['bitis'] is num
          ? data['bitis'] as num
          : num.tryParse((data['bitis'] ?? '0').toString()) ?? 0,
      bitisDk: data['bitisDk'] is num
          ? data['bitisDk'] as num
          : num.tryParse((data['bitisDk'] ?? '0').toString()) ?? 0,
    );
  }

  Future<void> _store(String cacheKey, List<SinavModel> items) async {
    final cloned = items.toList(growable: false);
    final now = DateTime.now();
    _memory[cacheKey] = _TimedPracticeExams(items: cloned, cachedAt: now);
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs?.setString(
      '$_prefsPrefix:$cacheKey',
      jsonEncode({
        't': now.millisecondsSinceEpoch,
        'items': cloned
            .map((item) => <String, dynamic>{
                  'id': item.docID,
                  'd': <String, dynamic>{
                    'cover': item.cover,
                    'sinavTuru': item.sinavTuru,
                    'timeStamp': item.timeStamp,
                    'sinavAciklama': item.sinavAciklama,
                    'sinavAdi': item.sinavAdi,
                    'kpssSecilenLisans': item.kpssSecilenLisans,
                    'dersler': item.dersler,
                    'taslak': item.taslak,
                    'public': item.public,
                    'userID': item.userID,
                    'soruSayilari': item.soruSayilari,
                    'bitis': item.bitis,
                    'bitisDk': item.bitisDk,
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

  List<SinavModel>? _getFromMemory(String cacheKey) {
    final entry = _memory[cacheKey];
    if (entry == null) return null;
    final fresh = DateTime.now().difference(entry.cachedAt) <= _ttl;
    if (!fresh) return null;
    return entry.items.toList(growable: false);
  }

  Future<List<SinavModel>?> _getFromPrefs(String cacheKey) async {
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
            (e) => _fromDoc(
              (e['id'] ?? '').toString(),
              Map<String, dynamic>.from((e['d'] as Map?) ?? const {}),
            ),
          )
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

  List<List<String>> _chunkIds(List<String> ids, int size) {
    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += size) {
      final end = (i + size < ids.length) ? i + size : ids.length;
      chunks.add(ids.sublist(i, end));
    }
    return chunks;
  }

  SoruModel? _questionFromMap(Map<String, dynamic> raw) {
    final docId = (raw['id'] ?? '').toString();
    final resolvedDocId = (raw['_docId'] ?? docId).toString();
    if (resolvedDocId.isEmpty) return null;
    final numericId = raw['id'] is num
        ? raw['id'] as num
        : num.tryParse((raw['questionId'] ?? '0').toString()) ?? 0;
    return SoruModel(
      id: numericId.toInt(),
      soru: (raw['soru'] ?? '').toString(),
      ders: (raw['ders'] ?? '').toString(),
      konu: (raw['konu'] ?? '').toString(),
      dogruCevap: (raw['dogruCevap'] ?? '').toString(),
      docID: resolvedDocId,
    );
  }
}

class PracticeExamPage {
  const PracticeExamPage({
    required this.items,
    required this.lastDocument,
    required this.hasMore,
  });

  final List<SinavModel> items;
  final DocumentSnapshot? lastDocument;
  final bool hasMore;
}

class _TimedPracticeExams {
  const _TimedPracticeExams({
    required this.items,
    required this.cachedAt,
  });

  final List<SinavModel> items;
  final DateTime cachedAt;
}

class _TimedPracticeExamBool {
  const _TimedPracticeExamBool({
    required this.value,
    required this.cachedAt,
  });

  final bool value;
  final DateTime cachedAt;
}
