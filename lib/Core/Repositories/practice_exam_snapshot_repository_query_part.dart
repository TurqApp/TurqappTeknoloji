part of 'practice_exam_snapshot_repository.dart';

extension PracticeExamSnapshotRepositoryQueryPart
    on PracticeExamSnapshotRepository {
  Stream<CachedResource<List<SinavModel>>> _openHomeImpl({
    required String userId,
    required int limit,
    required bool forceSync,
  }) {
    return _homeAdapter.open(
      EducationTypesenseDocIdQuery(
        entity: EducationTypesenseEntity.practiceExam,
        query: '*',
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'home',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> _loadHomeImpl({
    required String userId,
    required int limit,
    required bool forceSync,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<SinavModel>>> _openSearchImpl({
    required String query,
    required String userId,
    required int limit,
    required bool forceSync,
  }) {
    return _searchAdapter.open(
      EducationTypesenseDocIdQuery(
        entity: EducationTypesenseEntity.practiceExam,
        query: query,
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> _searchImpl({
    required String query,
    required String userId,
    required int limit,
    required bool forceSync,
  }) {
    return openSearch(
      query: query,
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<List<SinavModel>?> _loadWarmSnapshot(
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
    final items = await _practiceExamRepository.fetchByIds(
      docIds,
      cacheOnly: true,
    );
    return items.isEmpty ? null : items;
  }
}
