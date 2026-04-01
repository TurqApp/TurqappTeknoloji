part of 'question_bank_snapshot_repository.dart';

Stream<CachedResource<List<QuestionBankModel>>> _openQuestionBankSearch(
  QuestionBankSnapshotRepository repository, {
  required String query,
  required String userId,
  int limit = ReadBudgetRegistry.questionBankSearchInitialLimit,
  bool forceSync = false,
}) async* {
  if (!await isPasajTabEnabled(PasajTabIds.questionBank)) {
    yield* pasajDisabledStream<List<QuestionBankModel>>(
      const <QuestionBankModel>[],
    );
    return;
  }
  yield* repository._searchAdapter.open(
    EducationTypesenseQuery(
      entity: EducationTypesenseEntity.workout,
      query: query,
      limit: limit,
      page: 1,
      userId: userId,
      scopeTag: 'search',
    ),
    forceSync: forceSync,
  );
}

Future<List<QuestionBankModel>?> _loadWarmQuestionBankSnapshot(
  EducationTypesenseQuery query,
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
  final items = raw.hits
      .map(QuestionBankModel.fromTypesenseHit)
      .where((item) => item.docID.isNotEmpty)
      .toList(growable: false);
  return items.isEmpty ? null : items;
}

Map<String, dynamic> _encodeQuestionBankItems(List<QuestionBankModel> items) {
  return <String, dynamic>{
    'items': items.map((item) => item.toJson()).toList(growable: false),
  };
}

List<QuestionBankModel> _decodeQuestionBankItems(Map<String, dynamic> json) {
  final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
  return rawItems
      .whereType<Map>()
      .map((raw) => QuestionBankModel.fromJson(Map<String, dynamic>.from(raw)))
      .where((item) => item.docID.isNotEmpty)
      .toList(growable: false);
}

extension QuestionBankSnapshotRepositoryRuntimeX
    on QuestionBankSnapshotRepository {
  Stream<CachedResource<List<QuestionBankModel>>> openSearch({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.questionBankSearchInitialLimit,
    bool forceSync = false,
  }) {
    return _openQuestionBankSearch(
      this,
      query: query,
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<QuestionBankModel>>> search({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.questionBankSearchInitialLimit,
    bool forceSync = false,
  }) {
    return openSearch(
      query: query,
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<List<QuestionBankModel>> fetchCategoryPoolDocs(
    String anaBaslik,
    String sinavTuru,
    String ders, {
    int? limit,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.questionBank)) {
      return const <QuestionBankModel>[];
    }
    final filterBy = <String>[
      'active:=true',
      'anaBaslik:=${_typesenseFilterValue(anaBaslik)}',
      'sinavTuru:=${_typesenseFilterValue(sinavTuru)}',
      'ders:=${_typesenseFilterValue(ders)}',
    ].join(' && ');

    final docs = <QuestionBankModel>[];
    final perPage = limit == null ? 250 : limit.clamp(1, 250);
    var page = 1;

    while (true) {
      final result = await TypesenseEducationSearchService.instance.searchHits(
        entity: EducationTypesenseEntity.workout,
        query: '*',
        limit: perPage,
        page: page,
        filterBy: filterBy,
        sortBy: 'seq:asc',
      );
      docs.addAll(
        result.hits.map(QuestionBankModel.fromTypesenseHit),
      );
      if (limit != null && docs.length >= limit) {
        break;
      }
      if (result.hits.length < perPage) {
        break;
      }
      page += 1;
    }

    return limit == null ? docs : docs.take(limit).toList(growable: false);
  }

  String _typesenseFilterValue(String value) =>
      '`${value.trim().replaceAll('`', r'\`')}`';
}
