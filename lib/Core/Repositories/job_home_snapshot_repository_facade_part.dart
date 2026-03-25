part of 'job_home_snapshot_repository.dart';

extension JobHomeSnapshotRepositoryFacadePart on JobHomeSnapshotRepository {
  Stream<CachedResource<List<JobModel>>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.jobHomeInitialLimit,
    bool forceSync = false,
  }) {
    return _homeAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.job,
        query: '*',
        limit: limit,
        userId: userId,
        scopeTag: 'home',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<JobModel>>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.jobHomeInitialLimit,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<JobModel>>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.job,
        query: query,
        limit: limit,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<JobModel>>> search({
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
}
