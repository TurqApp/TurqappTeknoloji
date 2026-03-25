part of 'tutoring_snapshot_repository.dart';

extension TutoringSnapshotRepositoryFacadePart on TutoringSnapshotRepository {
  Stream<CachedResource<List<TutoringModel>>> openHome({
    required String userId,
    int limit = 30,
    int page = 1,
    bool forceSync = false,
  }) {
    return _homeAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.tutoring,
        query: '*',
        limit: limit,
        page: page,
        userId: userId,
        scopeTag: page <= 1 ? 'home' : 'home_page_$page',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TutoringModel>>> loadHome({
    required String userId,
    int limit = 30,
    int page = 1,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      page: page,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<TutoringModel>>> openSearch({
    required String userId,
    required String query,
    int limit = 40,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.tutoring,
        query: query,
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<TutoringModel>>> search({
    required String userId,
    required String query,
    int limit = 40,
    bool forceSync = false,
  }) {
    return openSearch(
      userId: userId,
      query: query,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }
}
