part of 'answer_key_snapshot_repository.dart';

AnswerKeySnapshotRepository? maybeFindAnswerKeySnapshotRepository() =>
    _maybeFindAnswerKeySnapshotRepository();

AnswerKeySnapshotRepository ensureAnswerKeySnapshotRepository() =>
    _ensureAnswerKeySnapshotRepository();

extension AnswerKeySnapshotRepositoryFacadePart on AnswerKeySnapshotRepository {
  Future<CachedResource<List<BookletModel>>> loadCachedExamType({
    required String userId,
    required String examType,
  }) {
    final query = AnswerKeyExamTypeQuery(
      userId: userId,
      examType: examType,
    );
    final schemaVersion = CacheFirstPolicyRegistry.schemaVersionForSurface(
      _answerKeyTypeSurfaceKey,
    );
    final key = ScopedSnapshotKey(
      surfaceKey: _answerKeyTypeSurfaceKey,
      userId: userId.trim(),
      scopeId: query.buildScopeId(schemaVersion: schemaVersion),
    );
    return _coordinator.bootstrap(
      key,
      schemaVersion: schemaVersion,
    );
  }

  Stream<CachedResource<List<BookletModel>>> openExamType({
    required String userId,
    required String examType,
    bool forceSync = false,
  }) {
    return _typePipeline.open(
      AnswerKeyExamTypeQuery(
        userId: userId,
        examType: examType,
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<BookletModel>>> loadExamType({
    required String userId,
    required String examType,
    bool forceSync = false,
  }) {
    return openExamType(
      userId: userId,
      examType: examType,
      forceSync: forceSync,
    ).last;
  }

  Future<CachedResource<List<BookletModel>>> loadCachedOwner({
    required String userId,
  }) {
    final query = AnswerKeyOwnerQuery(userId: userId);
    final schemaVersion = CacheFirstPolicyRegistry.schemaVersionForSurface(
      _answerKeyOwnerSurfaceKey,
    );
    final key = ScopedSnapshotKey(
      surfaceKey: _answerKeyOwnerSurfaceKey,
      userId: userId.trim(),
      scopeId: query.buildScopeId(schemaVersion: schemaVersion),
    );
    return _coordinator.bootstrap(
      key,
      schemaVersion: schemaVersion,
    );
  }

  Stream<CachedResource<List<BookletModel>>> openOwner({
    required String userId,
    bool forceSync = false,
  }) {
    return _ownerPipeline.open(
      AnswerKeyOwnerQuery(userId: userId),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<BookletModel>>> loadOwner({
    required String userId,
    bool forceSync = false,
  }) {
    return openOwner(
      userId: userId,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<BookletModel>>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.answerKeyHomeInitialLimit,
    bool forceSync = false,
  }) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this).openHome(
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Future<CachedResource<List<BookletModel>>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.answerKeyHomeInitialLimit,
    bool forceSync = false,
  }) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this).loadHome(
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Stream<CachedResource<List<BookletModel>>> openSearch({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.answerKeySearchInitialLimit,
    bool forceSync = false,
  }) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this).openSearch(
        query: query,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Future<CachedResource<List<BookletModel>>> search({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.answerKeySearchInitialLimit,
    bool forceSync = false,
  }) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this).search(
        query: query,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );
}
