part of 'cikmis_sorular_repository_parts.dart';

extension CikmisSorularRepositoryDetailPart on CikmisSorularRepository {
  static const String _assetPastQuestionsManifestPath =
      'assets/data/past_questions_manifest.json';

  int _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '').toString()) ?? 0;
  }

  num _asNum(Object? value) {
    if (value is num) return value;
    return num.tryParse((value ?? '').toString()) ?? 0;
  }

  double _asDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse((value ?? '').toString()) ?? 0;
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

  Future<List<Map<String, dynamic>>> _fetchRootDocsFromManifest() async {
    try {
      final raw = await rootBundle.loadString(_assetPastQuestionsManifestPath);
      if (raw.trim().isNotEmpty) {
        final decoded = jsonDecode(raw);
        final rawItems = switch (decoded) {
          List<dynamic> list => list,
          Map<String, dynamic> map =>
            (map['items'] as List<dynamic>?) ?? const [],
          _ => const <dynamic>[],
        };
        final docs = rawItems
            .whereType<Map>()
            .map((item) =>
                _normalizeManifestRootDoc(Map<String, dynamic>.from(item)))
            .where(_isActiveRootDoc)
            .toList(growable: true);
        docs.sort(_compareRootDocs);
        if (docs.isNotEmpty) {
          return docs;
        }
      }
    } catch (_) {}

    try {
      final bytes = await _storage
          .ref('questions/questions_manifest.json')
          .getData(4 * 1024 * 1024);
      if (bytes == null || bytes.isEmpty) return const <Map<String, dynamic>>[];
      final decoded = jsonDecode(utf8.decode(bytes));
      final rawItems = switch (decoded) {
        List<dynamic> list => list,
        Map<String, dynamic> map =>
          (map['items'] as List<dynamic>?) ?? const [],
        _ => const <dynamic>[],
      };
      final docs = rawItems
          .whereType<Map>()
          .map((item) =>
              _normalizeManifestRootDoc(Map<String, dynamic>.from(item)))
          .where(_isActiveRootDoc)
          .toList(growable: true);
      docs.sort(_compareRootDocs);
      return docs;
    } catch (_) {
      return const <Map<String, dynamic>>[];
    }
  }

  int _compareRootDocs(Map<String, dynamic> a, Map<String, dynamic> b) {
    final seqA = _asInt(a['sira']);
    final seqB = _asInt(b['sira']);
    final bySeq = seqA.compareTo(seqB);
    if (bySeq != 0) return bySeq;
    final tsA = _asInt(a['timeStamp']);
    final tsB = _asInt(b['timeStamp']);
    return tsB.compareTo(tsA);
  }

  Map<String, dynamic> _normalizeRootDoc(
    String docId,
    Map<String, dynamic> data,
  ) {
    return <String, dynamic>{
      '_docId': docId,
      'anaBaslik': (data['anaBaslik'] ?? '').toString(),
      'sinavTuru': (data['sinavTuru'] ?? '').toString(),
      'yil': (data['yil'] ?? '').toString(),
      'baslik2': (data['baslik2'] ?? '').toString(),
      'baslik3': (data['baslik3'] ?? '').toString(),
      'dil': (data['dil'] ?? '').toString(),
      'sira': _asInt(data['sira']),
      'title': (data['title'] ?? '').toString(),
      'subtitle': (data['subtitle'] ?? '').toString(),
      'description': (data['description'] ?? '').toString(),
      'cover': (data['cover'] ?? data['soru'] ?? data['img'] ?? '').toString(),
      'timeStamp': data['timeStamp'] ?? 0,
      'active': data['active'],
      'iptal': data['iptal'],
      'deleted': data['deleted'],
    };
  }

  Map<String, dynamic> _normalizeManifestRootDoc(Map<String, dynamic> data) {
    final docId = (data['_docId'] ?? data['docId'] ?? '').toString();
    final normalized = _normalizeRootDoc(docId, data);
    final questionJsonPath = (data['questionJsonPath'] ?? '').toString();
    if (questionJsonPath.isNotEmpty) {
      normalized['questionJsonPath'] = questionJsonPath;
    }
    return normalized;
  }

  bool _isActiveRootDoc(Map<String, dynamic> doc) {
    final active = doc['active'];
    if (active is bool) return active;
    return doc['iptal'] != true && doc['deleted'] != true;
  }

  CikmisSorularinModeli _questionItemFromMap(Map<String, dynamic> doc) {
    return CikmisSorularinModeli(
      ders: (doc['ders'] ?? '').toString(),
      dogruCevap: (doc['dogruCevap'] ?? '').toString(),
      soru: (doc['soru'] ?? '').toString(),
      kacCevap: _asNum(doc['kacCevap']),
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
      timeStamp: _asNum(doc['timeStamp']),
      cikmisSoruID: (doc['cikmisSoruID'] ?? '').toString(),
      docID: (doc['_docId'] ?? '').toString(),
      soruSayisi: _asInt(doc['soruSayisi']),
      dogruSayisi: _asInt(doc['dogruSayisi']),
      yanlisSayisi: _asInt(doc['yanlisSayisi']),
      bosSayisi: _asInt(doc['bosSayisi']),
      net: _asDouble(doc['net']),
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
}
