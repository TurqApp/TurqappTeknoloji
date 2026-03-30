part of 'practice_exam_snapshot_repository.dart';

PracticeExamSnapshotRepository? maybeFindPracticeExamSnapshotRepository() {
  final isRegistered = Get.isRegistered<PracticeExamSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<PracticeExamSnapshotRepository>();
}

PracticeExamSnapshotRepository ensurePracticeExamSnapshotRepository() {
  final existing = maybeFindPracticeExamSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(PracticeExamSnapshotRepository(), permanent: true);
}

extension PracticeExamSnapshotRepositoryFacadePart
    on PracticeExamSnapshotRepository {
  Future<CachedResource<List<SinavModel>>> loadCachedAnswered({
    required String userId,
  }) {
    final query = PracticeExamAnsweredQuery(userId: userId);
    final surfaceKey = _practiceExamAnsweredSurfaceKey;
    final schemaVersion = CacheFirstPolicyRegistry.schemaVersionForSurface(
      surfaceKey,
    );
    final key = ScopedSnapshotKey(
      surfaceKey: surfaceKey,
      userId: userId.trim(),
      scopeId: query.buildScopeId(schemaVersion: schemaVersion),
    );
    return _coordinator.bootstrap(
      key,
      schemaVersion: schemaVersion,
    );
  }

  Stream<CachedResource<List<SinavModel>>> openAnswered({
    required String userId,
    bool forceSync = false,
  }) =>
      _openAnsweredImpl(
        userId: userId,
        forceSync: forceSync,
      );

  Future<CachedResource<List<SinavModel>>> loadAnswered({
    required String userId,
    bool forceSync = false,
  }) =>
      _loadAnsweredImpl(
        userId: userId,
        forceSync: forceSync,
      );

  Stream<CachedResource<List<SinavModel>>> openType({
    required String userId,
    required String examType,
    bool forceSync = false,
  }) =>
      _openTypeImpl(
        userId: userId,
        examType: examType,
        forceSync: forceSync,
      );

  Future<CachedResource<List<SinavModel>>> loadType({
    required String userId,
    required String examType,
    bool forceSync = false,
  }) =>
      _loadTypeImpl(
        userId: userId,
        examType: examType,
        forceSync: forceSync,
      );

  Stream<CachedResource<List<SinavModel>>> openOwner({
    required String userId,
    bool forceSync = false,
  }) =>
      _openOwnerImpl(
        userId: userId,
        forceSync: forceSync,
      );

  Future<CachedResource<List<SinavModel>>> loadOwner({
    required String userId,
    bool forceSync = false,
  }) =>
      _loadOwnerImpl(
        userId: userId,
        forceSync: forceSync,
      );

  Stream<CachedResource<List<SinavModel>>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.practiceExamHomeInitialLimit,
    bool forceSync = false,
  }) =>
      _openHomeImpl(
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Future<CachedResource<List<SinavModel>>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.practiceExamHomeInitialLimit,
    bool forceSync = false,
  }) =>
      _loadHomeImpl(
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Stream<CachedResource<List<SinavModel>>> openSearch({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.practiceExamSearchInitialLimit,
    bool forceSync = false,
  }) =>
      _openSearchImpl(
        query: query,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Future<CachedResource<List<SinavModel>>> search({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.practiceExamSearchInitialLimit,
    bool forceSync = false,
  }) =>
      _searchImpl(
        query: query,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );
}
