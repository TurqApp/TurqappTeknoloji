part of 'answer_key_snapshot_repository.dart';

AnswerKeySnapshotRepository? maybeFindAnswerKeySnapshotRepository() =>
    _maybeFindAnswerKeySnapshotRepository();

AnswerKeySnapshotRepository ensureAnswerKeySnapshotRepository() =>
    _ensureAnswerKeySnapshotRepository();

extension AnswerKeySnapshotRepositoryFacadePart on AnswerKeySnapshotRepository {
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
    int limit = 30,
    bool forceSync = false,
  }) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this).openHome(
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Future<CachedResource<List<BookletModel>>> loadHome({
    required String userId,
    int limit = 30,
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
    int limit = 40,
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
    int limit = 40,
    bool forceSync = false,
  }) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this).search(
        query: query,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );
}
