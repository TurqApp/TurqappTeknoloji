part of 'answer_key_snapshot_repository.dart';

extension _AnswerKeySnapshotRepositoryRuntimeX on AnswerKeySnapshotRepository {
  num _asAnswerKeyNum(Object? value) {
    if (value is num) return value;
    return num.tryParse((value ?? '0').toString()) ?? 0;
  }

  int _asAnswerKeyInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse((value ?? '0').toString()) ?? 0;
  }

  List<String> _asAnswerKeyStringList(Object? value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList(growable: false);
    }
    return const <String>[];
  }

  Stream<CachedResource<List<BookletModel>>> openHome({
    required String userId,
    int limit = 30,
    bool forceSync = false,
  }) {
    return _homeAdapter.open(
      EducationTypesenseDocIdQuery(
        entity: EducationTypesenseEntity.answerKey,
        query: '*',
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'home',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<BookletModel>>> loadHome({
    required String userId,
    int limit = 30,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<BookletModel>>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseDocIdQuery(
        entity: EducationTypesenseEntity.answerKey,
        query: query,
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<BookletModel>>> search({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return openSearch(
      query: query,
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<List<BookletModel>?> _loadWarmSnapshot(
    EducationTypesenseDocIdQuery query,
  ) async {
    final raw = await TypesenseEducationSearchService.instance.searchHits(
      entity: query.entity,
      query: query.query,
      limit: query.limit,
      page: query.page,
      filterBy: query.filterBy,
      sortBy: query.sortBy,
      cacheOnly: true,
    );
    final docIds = raw.hits
        .map((hit) => (hit['docId'] ?? hit['id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (docIds.isEmpty) return null;
    final items = await _bookletRepository.fetchByIds(
      docIds,
      cacheOnly: true,
    );
    return items.isEmpty ? null : items;
  }

  Map<String, dynamic> _encodeItems(List<BookletModel> items) {
    return <String, dynamic>{
      'items': items
          .map(
            (item) => <String, dynamic>{
              'docID': item.docID,
              'basimTarihi': item.basimTarihi,
              'baslik': item.baslik,
              'cover': item.cover,
              'dil': item.dil,
              'kaydet': item.kaydet,
              'sinavTuru': item.sinavTuru,
              'timeStamp': item.timeStamp,
              'yayinEvi': item.yayinEvi,
              'userID': item.userID,
              'viewCount': item.viewCount,
              'shortId': item.shortId,
              'shortUrl': item.shortUrl,
            },
          )
          .toList(growable: false),
    };
  }

  List<BookletModel> _decodeItems(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
          return BookletModel(
            dil: (item['dil'] ?? '').toString(),
            sinavTuru: (item['sinavTuru'] ?? '').toString(),
            cover: (item['cover'] ?? '').toString(),
            baslik: (item['baslik'] ?? '').toString(),
            timeStamp: _asAnswerKeyNum(item['timeStamp']),
            docID: (item['docID'] ?? '').toString(),
            kaydet: _asAnswerKeyStringList(item['kaydet']),
            basimTarihi: (item['basimTarihi'] ?? '').toString(),
            yayinEvi: (item['yayinEvi'] ?? '').toString(),
            userID: (item['userID'] ?? '').toString(),
            viewCount: _asAnswerKeyInt(item['viewCount']),
            shortId: (item['shortId'] ?? '').toString(),
            shortUrl: (item['shortUrl'] ?? '').toString(),
          );
        })
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }
}
