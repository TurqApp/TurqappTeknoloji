import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Models/Education/cikmis_soru_sonuc_model.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_cover_model.dart';

class CikmisSorularRepository extends GetxService {
  CikmisSorularRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'cikmis_sorular_repository_v1';
  final Map<String, _TimedJsonList> _memory = <String, _TimedJsonList>{};
  SharedPreferences? _prefs;

  static CikmisSorularRepository ensure() {
    if (Get.isRegistered<CikmisSorularRepository>()) {
      return Get.find<CikmisSorularRepository>();
    }
    return Get.put(CikmisSorularRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  Future<List<Map<String, dynamic>>> fetchRootDocs({
    bool preferCache = true,
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'root_docs';
    if (!forceRefresh && preferCache) {
      final cached = await _readList(cacheKey);
      if (cached != null) return cached;
    }
    bool cacheOnly = false,

    final snap = await _firestore
        .collection('questions')
        .orderBy('sira', descending: false)
        .get(const GetOptions(source: Source.serverAndCache));
    final docs = snap.docs
        .map((doc) => <String, dynamic>{'_docId': doc.id, ...doc.data()})
        .toList(growable: false);
    if (cacheOnly) return const <Map<String, dynamic>>[];

    await _writeList(cacheKey, docs);
    return docs;
  }

  Future<List<CikmisSorularCoverModel>> fetchCovers({
    bool preferCache = true,
    bool forceRefresh = false,
    bool cacheOnly = false,
  }) async {
    final docs = await fetchRootDocs(
      preferCache: preferCache,
      forceRefresh: forceRefresh,
      cacheOnly: cacheOnly,
    );
    final seen = <String>{};
    final items = <CikmisSorularCoverModel>[];
    for (final doc in docs) {
      final anaBaslik = (doc['anaBaslik'] ?? '').toString();
      final sinavTuru = (doc['sinavTuru'] ?? '').toString();
      if (anaBaslik.isEmpty || seen.contains(anaBaslik)) continue;
      seen.add(anaBaslik);
      items.add(CikmisSorularCoverModel(
        anaBaslik: anaBaslik,
        docID: (doc['_docId'] ?? '').toString(),
        sinavTuru: sinavTuru,
      ));
    }
    return items;
  }

  Future<List<Map<String, dynamic>>> fetchRootDocsByIds(
    List<String> ids, {
    bool preferCache = true,
  }) async {
    final wanted =
        ids.where((e) => e.trim().isNotEmpty).toList(growable: false);
    if (wanted.isEmpty) return const <Map<String, dynamic>>[];

    final resolved = <String, Map<String, dynamic>>{};
    if (preferCache) {
      final cached = await fetchRootDocs();
      for (final doc in cached) {
        final id = (doc['_docId'] ?? '').toString();
        if (id.isNotEmpty) {
          resolved[id] = Map<String, dynamic>.from(doc);
        }
      }
    }

    final missing = wanted.where((id) => !resolved.containsKey(id)).toList();
    for (var i = 0; i < missing.length; i += 10) {
      final end = (i + 10 > missing.length) ? missing.length : i + 10;
      final chunk = missing.sublist(i, end);
      final snap = await _firestore
          .collection('questions')
          .where(FieldPath.documentId, whereIn: chunk)
          .get(const GetOptions(source: Source.serverAndCache));
      for (final doc in snap.docs) {
        resolved[doc.id] = <String, dynamic>{
          '_docId': doc.id,
          ...doc.data(),
        };
      }
    }

    return wanted
        .map((id) => resolved[id])
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
  }

  Future<List<String>> distinctValues({
    required bool Function(Map<String, dynamic> doc) where,
    required String field,
    List<String>? priorityOrder,
    bool descendingNumeric = false,
  }) async {
    final docs = await fetchRootDocs();
    final values = <String>[];
    for (final doc in docs) {
      if (!where(doc)) continue;
      final value = (doc[field] ?? '').toString();
      if (value.isEmpty || values.contains(value)) continue;
      values.add(value);
    }

    if (priorityOrder != null && priorityOrder.isNotEmpty) {
      values.sort((a, b) {
        var ia = priorityOrder.indexOf(a);
        var ib = priorityOrder.indexOf(b);
        if (ia == -1) ia = priorityOrder.length;
        if (ib == -1) ib = priorityOrder.length;
        return ia.compareTo(ib);
      });
      return values;
    }

    if (descendingNumeric) {
      values.sort((a, b) {
        final pa = int.tryParse(a) ?? -1;
        final pb = int.tryParse(b) ?? -1;
        return pb.compareTo(pa);
      });
      return values;
    }

    values.sort();
    return values;
  }

  Future<String?> findQuestionDocId({
    required String anaBaslik,
    required String sinavTuru,
    required String yil,
    required String baslik2,
    required String baslik3,
  }) async {
    final docs = await fetchRootDocs();
    for (final doc in docs) {
      if ((doc['anaBaslik'] ?? '').toString() == anaBaslik &&
          (doc['sinavTuru'] ?? '').toString() == sinavTuru &&
          (doc['yil'] ?? '').toString() == yil &&
          (doc['baslik2'] ?? '').toString() == baslik2 &&
          (doc['baslik3'] ?? '').toString() == baslik3) {
        return (doc['_docId'] ?? '').toString();
      }
    }
    return null;
  }

  Future<List<CikmisSorularinModeli>> fetchQuestionItems(String docId) async {
    final cacheKey = 'questions:$docId';
    final cached = await _readList(cacheKey);
    if (cached != null) {
      return cached
          .map((doc) => CikmisSorularinModeli(
                ders: (doc['ders'] ?? '').toString(),
                dogruCevap: (doc['dogruCevap'] ?? '').toString(),
                soru: (doc['soru'] ?? '').toString(),
                kacCevap: (doc['kacCevap'] as num?) ?? 0,
                docID: (doc['_docId'] ?? '').toString(),
                soruNo: (doc['soruNo'] ?? '').toString(),
              ))
          .toList(growable: false);
    }

    final baseDoc = _firestore.collection('questions').doc(docId);
    var questionsSnap = await baseDoc
        .collection('questions')
        .get(const GetOptions(source: Source.serverAndCache));
    if (questionsSnap.docs.isEmpty) {
      questionsSnap = await baseDoc
          .collection('Sorular')
          .get(const GetOptions(source: Source.serverAndCache));
    }
    final raw = questionsSnap.docs
        .map((doc) => <String, dynamic>{'_docId': doc.id, ...doc.data()})
        .toList(growable: false);
    await _writeList(cacheKey, raw);
    return raw
        .map((doc) => CikmisSorularinModeli(
              ders: (doc['ders'] ?? '').toString(),
              dogruCevap: (doc['dogruCevap'] ?? '').toString(),
              soru: (doc['soru'] ?? '').toString(),
              kacCevap: (doc['kacCevap'] as num?) ?? 0,
              docID: (doc['_docId'] ?? '').toString(),
              soruNo: (doc['soruNo'] ?? '').toString(),
            ))
        .toList(growable: false);
  }

  Future<List<CikmisSoruSonucModel>> fetchUserResults(String uid) async {
    final cacheKey = 'results:$uid';
    final cached = await _readList(cacheKey);
    if (cached != null) {
      return cached
          .map((doc) => CikmisSoruSonucModel(
                anaBaslik: (doc['anaBaslik'] ?? '').toString(),
                sinavTuru: (doc['sinavTuru'] ?? '').toString(),
                yil: (doc['yil'] ?? '').toString(),
                baslik2: (doc['baslik2'] ?? '').toString(),
                baslik3: (doc['baslik3'] ?? '').toString(),
                userID: (doc['userID'] ?? '').toString(),
                cevaplar: List<String>.from(doc['cevaplar'] ?? const []),
                timeStamp: (doc['timeStamp'] as num?) ?? 0,
                cikmisSoruID: (doc['cikmisSoruID'] ?? '').toString(),
                dogruCevaplar:
                    List<String>.from(doc['dogruCevaplar'] ?? const []),
                docID: (doc['_docId'] ?? '').toString(),
              ))
          .toList(growable: false);
    }

    final snap = await _firestore
        .collection('questionsAnswers')
        .where('userID', isEqualTo: uid)
        .get(const GetOptions(source: Source.serverAndCache));
    final raw = snap.docs
        .map((doc) => <String, dynamic>{'_docId': doc.id, ...doc.data()})
        .toList(growable: false);
    await _writeList(cacheKey, raw);
    return raw
        .map((doc) => CikmisSoruSonucModel(
              anaBaslik: (doc['anaBaslik'] ?? '').toString(),
              sinavTuru: (doc['sinavTuru'] ?? '').toString(),
              yil: (doc['yil'] ?? '').toString(),
              baslik2: (doc['baslik2'] ?? '').toString(),
              baslik3: (doc['baslik3'] ?? '').toString(),
              userID: (doc['userID'] ?? '').toString(),
              cevaplar: List<String>.from(doc['cevaplar'] ?? const []),
              timeStamp: (doc['timeStamp'] as num?) ?? 0,
              cikmisSoruID: (doc['cikmisSoruID'] ?? '').toString(),
              dogruCevaplar:
                  List<String>.from(doc['dogruCevaplar'] ?? const []),
              docID: (doc['_docId'] ?? '').toString(),
            ))
        .toList(growable: false);
  }

  Future<void> saveResult({
    required String uid,
    required String anaBaslik,
    required String sinavTuru,
    required String yil,
    required String baslik2,
    required String baslik3,
    required String cikmisSoruID,
    required List<String> cevaplar,
    required List<String> dogruCevaplar,
  }) async {
    await _firestore.collection('questionsAnswers').add({
      'cevaplar': cevaplar,
      'dogruCevaplar': dogruCevaplar,
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'anaBaslik': anaBaslik,
      'sinavTuru': sinavTuru,
      'yil': yil,
      'baslik2': baslik2,
      'baslik3': baslik3,
      'cikmisSoruID': cikmisSoruID,
      'userID': uid,
    });
    final cacheKey = 'results:$uid';
    _memory.remove(cacheKey);
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.remove('$_prefsPrefix::$cacheKey');
  }

  Future<List<Map<String, dynamic>>?> _readList(String key) async {
    final memory = _memory[key];
    if (memory != null && DateTime.now().difference(memory.cachedAt) <= _ttl) {
      return List<Map<String, dynamic>>.from(memory.items);
    }
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    final raw = prefs.getString('$_prefsPrefix::$key');
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final cachedAt = DateTime.tryParse(decoded['cachedAt'] as String? ?? '');
    if (cachedAt == null || DateTime.now().difference(cachedAt) > _ttl) {
      await prefs.remove('$_prefsPrefix::$key');
      return null;
    }
    final items = (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);
    _memory[key] = _TimedJsonList(items: items, cachedAt: DateTime.now());
    return items;
  }

  Future<void> _writeList(String key, List<Map<String, dynamic>> items) async {
    _memory[key] = _TimedJsonList(
      items: List<Map<String, dynamic>>.from(items),
      cachedAt: DateTime.now(),
    );
    final prefs = _prefs ??= await SharedPreferences.getInstance();
    await prefs.setString(
      '$_prefsPrefix::$key',
      jsonEncode(<String, dynamic>{
        'cachedAt': DateTime.now().toIso8601String(),
        'items': items,
      }),
    );
  }
}

class _TimedJsonList {
  const _TimedJsonList({
    required this.items,
    required this.cachedAt,
  });

  final List<Map<String, dynamic>> items;
  final DateTime cachedAt;
}
