part of 'practice_exam_snapshot_repository.dart';

extension PracticeExamSnapshotRepositoryQueryPart
    on PracticeExamSnapshotRepository {
  Stream<CachedResource<List<SinavModel>>> _openAnsweredImpl({
    required String userId,
    required bool forceSync,
  }) {
    return _answeredPipeline.open(
      PracticeExamAnsweredQuery(userId: userId),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> _loadAnsweredImpl({
    required String userId,
    required bool forceSync,
  }) {
    return openAnswered(
      userId: userId,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<SinavModel>>> _openTypeImpl({
    required String userId,
    required String examType,
    required bool forceSync,
  }) {
    return _typePipeline.open(
      PracticeExamTypeQuery(
        userId: userId,
        examType: examType,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> _loadTypeImpl({
    required String userId,
    required String examType,
    required bool forceSync,
  }) {
    return openType(
      userId: userId,
      examType: examType,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<SinavModel>>> _openOwnerImpl({
    required String userId,
    required bool forceSync,
  }) {
    return _ownerPipeline.open(
      PracticeExamOwnerQuery(userId: userId),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> _loadOwnerImpl({
    required String userId,
    required bool forceSync,
  }) {
    return openOwner(
      userId: userId,
      forceSync: forceSync,
    ).last;
  }

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
}
