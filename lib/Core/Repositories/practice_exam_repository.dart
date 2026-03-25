import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/ders_ve_sonuclar_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/soru_model.dart';

part 'practice_exam_repository_query_part.dart';
part 'practice_exam_repository_detail_part.dart';
part 'practice_exam_repository_models_part.dart';

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

  static PracticeExamRepository? maybeFind() {
    final isRegistered = Get.isRegistered<PracticeExamRepository>();
    if (!isRegistered) return null;
    return Get.find<PracticeExamRepository>();
  }

  static PracticeExamRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PracticeExamRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
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
      participantCount: data['participantCount'] is num
          ? data['participantCount'] as num
          : num.tryParse((data['participantCount'] ?? '0').toString()) ?? 0,
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
                    'participantCount': item.participantCount,
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
