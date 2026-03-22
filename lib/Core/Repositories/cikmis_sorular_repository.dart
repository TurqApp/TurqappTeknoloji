import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Models/Education/cikmis_soru_sonuc_model.dart';
import 'package:turqappv2/Modules/Education/CikmisSorular/cikmis_sorular_cover_model.dart';

class CikmisSorularRepository extends GetxService {
  CikmisSorularRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  static const Duration _ttl = Duration(hours: 12);
  static const String _prefsPrefix = 'cikmis_sorular_repository_v1';
  final Map<String, _TimedJsonList> _memory = <String, _TimedJsonList>{};
  SharedPreferences? _prefs;

  static CikmisSorularRepository? maybeFind() {
    final isRegistered = Get.isRegistered<CikmisSorularRepository>();
    if (!isRegistered) return null;
    return Get.find<CikmisSorularRepository>();
  }

  static CikmisSorularRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
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
    bool cacheOnly = false,
  }) async {
    const cacheKey = 'root_docs';
    if (!forceRefresh && preferCache) {
      final cached = await _readList(cacheKey);
      if (cached != null) return cached;
    }

    if (cacheOnly) return const <Map<String, dynamic>>[];

    final docs = await _fetchRootDocsFromTypesense();
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
    for (var i = 0; i < missing.length; i += 50) {
      final end = (i + 50 > missing.length) ? missing.length : i + 50;
      final chunk = missing.sublist(i, end);
      final result = await TypesenseEducationSearchService.instance.searchHits(
        entity: EducationTypesenseEntity.pastQuestion,
        query: '*',
        limit: chunk.length,
        page: 1,
        filterBy: TypesenseEducationSearchService.filterIn('docId', chunk),
        sortBy: 'seq:asc,timeStamp:desc',
      );
      for (final hit in result.hits) {
        final mapped = _rootDocFromHit(hit);
        final docId = (mapped['_docId'] ?? '').toString();
        if (docId.isNotEmpty) {
          resolved[docId] = mapped;
        }
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
      return cached.map(_questionItemFromMap).toList(growable: false);
    }

    final fromStorage = await _fetchQuestionsFromStorage(docId);
    if (fromStorage != null) {
      await _writeList(cacheKey, fromStorage);
      return fromStorage.map(_questionItemFromMap).toList(growable: false);
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
    return raw.map(_questionItemFromMap).toList(growable: false);
  }

  Future<List<CikmisSoruSonucModel>> fetchUserResults(String uid) async {
    final cacheKey = 'results:$uid';
    final cached = await _readList(cacheKey);
    if (cached != null) {
      return cached.map(_resultFromMap).toList(growable: false);
    }
    return const <CikmisSoruSonucModel>[];
  }

  Future<void> saveResult({
    required String uid,
    required String anaBaslik,
    required String sinavTuru,
    required String yil,
    required String baslik2,
    required String baslik3,
    required String cikmisSoruID,
    required int soruSayisi,
    required int dogruSayisi,
    required int yanlisSayisi,
    required int bosSayisi,
    required double net,
  }) async {
    final cacheKey = 'results:$uid';
    final current = await fetchUserResults(uid);
    final raw = <Map<String, dynamic>>[
      <String, dynamic>{
        '_docId': DateTime.now().microsecondsSinceEpoch.toString(),
        'timeStamp': DateTime.now().millisecondsSinceEpoch,
        'anaBaslik': anaBaslik,
        'sinavTuru': sinavTuru,
        'yil': yil,
        'baslik2': baslik2,
        'baslik3': baslik3,
        'cikmisSoruID': cikmisSoruID,
        'userID': uid,
        'soruSayisi': soruSayisi,
        'dogruSayisi': dogruSayisi,
        'yanlisSayisi': yanlisSayisi,
        'bosSayisi': bosSayisi,
        'net': net,
      },
      ...current.map(_resultToMap),
    ];
    await _writeList(cacheKey, raw);
  }

  Future<List<Map<String, dynamic>>> _fetchRootDocsFromTypesense() async {
    final docs = <Map<String, dynamic>>[];
    var page = 1;
    const limit = 250;
    while (true) {
      final result = await TypesenseEducationSearchService.instance.searchHits(
        entity: EducationTypesenseEntity.pastQuestion,
        query: '*',
        limit: limit,
        page: page,
        filterBy: 'active:=true',
        sortBy: 'seq:asc,timeStamp:desc',
      );
      final chunk = result.hits
          .map(_rootDocFromHit)
          .where((doc) => (doc['_docId'] ?? '').toString().isNotEmpty)
          .toList(growable: false);
      docs.addAll(chunk);
      if ((page * limit) >= result.found || chunk.isEmpty) break;
      page++;
    }
    return docs;
  }

  Map<String, dynamic> _rootDocFromHit(Map<String, dynamic> hit) {
    return <String, dynamic>{
      '_docId': (hit['docId'] ?? hit['id'] ?? '').toString(),
      'anaBaslik': (hit['anaBaslik'] ?? '').toString(),
      'sinavTuru': (hit['sinavTuru'] ?? '').toString(),
      'yil': (hit['yil'] ?? '').toString(),
      'baslik2': (hit['baslik2'] ?? '').toString(),
      'baslik3': (hit['baslik3'] ?? '').toString(),
      'dil': (hit['dil'] ?? '').toString(),
      'sira': (hit['seq'] as num?)?.toInt() ?? 0,
      'title': (hit['title'] ?? '').toString(),
      'subtitle': (hit['subtitle'] ?? '').toString(),
      'description': (hit['description'] ?? '').toString(),
      'cover': (hit['cover'] ?? '').toString(),
      'timeStamp': hit['timeStamp'] ?? 0,
    };
  }

  CikmisSorularinModeli _questionItemFromMap(Map<String, dynamic> doc) {
    return CikmisSorularinModeli(
      ders: (doc['ders'] ?? '').toString(),
      dogruCevap: (doc['dogruCevap'] ?? '').toString(),
      soru: (doc['soru'] ?? '').toString(),
      kacCevap: (doc['kacCevap'] as num?) ?? 0,
      docID: (doc['_docId'] ?? doc['docID'] ?? '').toString(),
      soruNo: (doc['soruNo'] ?? '').toString(),
    );
  }

  CikmisSoruSonucModel _resultFromMap(Map<String, dynamic> doc) {
    return CikmisSoruSonucModel(
      anaBaslik: (doc['anaBaslik'] ?? '').toString(),
      sinavTuru: (doc['sinavTuru'] ?? '').toString(),
      yil: (doc['yil'] ?? '').toString(),
      baslik2: (doc['baslik2'] ?? '').toString(),
      baslik3: (doc['baslik3'] ?? '').toString(),
      userID: (doc['userID'] ?? '').toString(),
      timeStamp: (doc['timeStamp'] as num?) ?? 0,
      cikmisSoruID: (doc['cikmisSoruID'] ?? '').toString(),
      docID: (doc['_docId'] ?? '').toString(),
      soruSayisi: (doc['soruSayisi'] as num?)?.toInt() ?? 0,
      dogruSayisi: (doc['dogruSayisi'] as num?)?.toInt() ?? 0,
      yanlisSayisi: (doc['yanlisSayisi'] as num?)?.toInt() ?? 0,
      bosSayisi: (doc['bosSayisi'] as num?)?.toInt() ?? 0,
      net: (doc['net'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> _resultToMap(CikmisSoruSonucModel model) {
    return <String, dynamic>{
      '_docId': model.docID,
      'timeStamp': model.timeStamp,
      'anaBaslik': model.anaBaslik,
      'sinavTuru': model.sinavTuru,
      'yil': model.yil,
      'baslik2': model.baslik2,
      'baslik3': model.baslik3,
      'cikmisSoruID': model.cikmisSoruID,
      'userID': model.userID,
      'soruSayisi': model.soruSayisi,
      'dogruSayisi': model.dogruSayisi,
      'yanlisSayisi': model.yanlisSayisi,
      'bosSayisi': model.bosSayisi,
      'net': model.net,
    };
  }

  Future<List<Map<String, dynamic>>?> _fetchQuestionsFromStorage(
    String docId,
  ) async {
    try {
      final bytes = await _storage
          .ref('questions/$docId/questions.json')
          .getData(12 * 1024 * 1024);
      if (bytes == null || bytes.isEmpty) return null;
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is List) {
        return decoded
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList(growable: false);
      }
      if (decoded is Map<String, dynamic>) {
        final items = decoded['items'];
        if (items is List) {
          return items
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);
        }
      }
    } catch (_) {}
    return null;
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
