part of 'cikmis_sorular_repository.dart';

extension CikmisSorularRepositoryDetailPart on CikmisSorularRepository {
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
}
