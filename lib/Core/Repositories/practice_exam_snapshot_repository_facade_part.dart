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
    int limit = ReadBudgetRegistry.practiceExamAnsweredInitialLimit,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.onlineExam)) {
      return pasajDisabledResource<List<SinavModel>>(const <SinavModel>[]);
    }
    final effectiveLimit =
        ReadBudgetRegistry.resolvePracticeExamAnsweredInitialLimit(limit);
    final query = PracticeExamAnsweredQuery(
      userId: userId,
      limit: effectiveLimit,
    );
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
    int limit = ReadBudgetRegistry.practiceExamAnsweredInitialLimit,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.onlineExam)) {
      yield* pasajDisabledStream<List<SinavModel>>(const <SinavModel>[]);
      return;
    }
    yield* _openAnsweredImpl(
      userId: userId,
      limit: ReadBudgetRegistry.resolvePracticeExamAnsweredInitialLimit(limit),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> loadAnswered({
    required String userId,
    int limit = ReadBudgetRegistry.practiceExamAnsweredInitialLimit,
    bool forceSync = false,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.onlineExam)) {
      return pasajDisabledResource<List<SinavModel>>(const <SinavModel>[]);
    }
    return _loadAnsweredImpl(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    );
  }

  Stream<CachedResource<List<SinavModel>>> openType({
    required String userId,
    required String examType,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.onlineExam)) {
      yield* pasajDisabledStream<List<SinavModel>>(const <SinavModel>[]);
      return;
    }
    yield* _openTypeImpl(
      userId: userId,
      examType: examType,
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> loadType({
    required String userId,
    required String examType,
    bool forceSync = false,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.onlineExam)) {
      return pasajDisabledResource<List<SinavModel>>(const <SinavModel>[]);
    }
    return _loadTypeImpl(
      userId: userId,
      examType: examType,
      forceSync: forceSync,
    );
  }

  Stream<CachedResource<List<SinavModel>>> openOwner({
    required String userId,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.onlineExam)) {
      yield* pasajDisabledStream<List<SinavModel>>(const <SinavModel>[]);
      return;
    }
    yield* _openOwnerImpl(
      userId: userId,
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> loadOwner({
    required String userId,
    bool forceSync = false,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.onlineExam)) {
      return pasajDisabledResource<List<SinavModel>>(const <SinavModel>[]);
    }
    return _loadOwnerImpl(
      userId: userId,
      forceSync: forceSync,
    );
  }

  Stream<CachedResource<List<SinavModel>>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.practiceExamHomeInitialLimit,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.onlineExam)) {
      yield* pasajDisabledStream<List<SinavModel>>(const <SinavModel>[]);
      return;
    }
    yield* _openHomeImpl(
      userId: userId,
      limit: ReadBudgetRegistry.resolvePracticeExamHomeInitialLimit(limit),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.practiceExamHomeInitialLimit,
    bool forceSync = false,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.onlineExam)) {
      return pasajDisabledResource<List<SinavModel>>(const <SinavModel>[]);
    }
    return _loadHomeImpl(
      userId: userId,
      limit: ReadBudgetRegistry.resolvePracticeExamHomeInitialLimit(limit),
      forceSync: forceSync,
    );
  }

  Stream<CachedResource<List<SinavModel>>> openSearch({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.practiceExamSearchInitialLimit,
    bool forceSync = false,
  }) async* {
    if (!await isPasajTabEnabled(PasajTabIds.onlineExam)) {
      yield* pasajDisabledStream<List<SinavModel>>(const <SinavModel>[]);
      return;
    }
    yield* _openSearchImpl(
      query: query,
      userId: userId,
      limit: ReadBudgetRegistry.resolvePracticeExamSearchInitialLimit(limit),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> search({
    required String query,
    required String userId,
    int limit = ReadBudgetRegistry.practiceExamSearchInitialLimit,
    bool forceSync = false,
  }) async {
    if (!await isPasajTabEnabled(PasajTabIds.onlineExam)) {
      return pasajDisabledResource<List<SinavModel>>(const <SinavModel>[]);
    }
    return _searchImpl(
      query: query,
      userId: userId,
      limit: ReadBudgetRegistry.resolvePracticeExamSearchInitialLimit(limit),
      forceSync: forceSync,
    );
  }

  Future<void> invalidateUserScopedSurfaces(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;
    await Future.wait(<Future<void>>[
      _coordinator.clearSurface(_practiceExamHomeSurfaceKey,
          userId: normalized),
      _coordinator.clearSurface(
        _practiceExamSearchSurfaceKey,
        userId: normalized,
      ),
      _coordinator.clearSurface(
        _practiceExamOwnerSurfaceKey,
        userId: normalized,
      ),
      _coordinator.clearSurface(_practiceExamTypeSurfaceKey,
          userId: normalized),
      _coordinator.clearSurface(
        _practiceExamAnsweredSurfaceKey,
        userId: normalized,
      ),
    ]);
  }

  Future<void> invalidateAnsweredSurface(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) return;
    await _coordinator.clearSurface(
      _practiceExamAnsweredSurfaceKey,
      userId: normalized,
    );
  }

  Future<void> invalidateAllSurfaces() async {
    await Future.wait(<Future<void>>[
      _coordinator.clearSurface(_practiceExamHomeSurfaceKey),
      _coordinator.clearSurface(_practiceExamSearchSurfaceKey),
      _coordinator.clearSurface(_practiceExamOwnerSurfaceKey),
      _coordinator.clearSurface(_practiceExamTypeSurfaceKey),
      _coordinator.clearSurface(_practiceExamAnsweredSurfaceKey),
    ]);
  }
}
