part of 'answer_key_snapshot_repository.dart';

const String _answerKeyHomeSurfaceKey = 'answer_key_home_snapshot';
const String _answerKeySearchSurfaceKey = 'answer_key_search_snapshot';
const String _answerKeyOwnerSurfaceKey = 'answer_key_owner_snapshot';
const String _answerKeyTypeSurfaceKey = 'answer_key_type_snapshot';

class AnswerKeyOwnerQuery {
  const AnswerKeyOwnerQuery({
    required this.userId,
  });

  final String userId;

  String buildScopeId({
    required int schemaVersion,
  }) {
    return CacheScopeNamespace.buildQueryScope(
      userId: userId,
      limit: 0,
      scopeTag: 'owner',
      schemaVersion: schemaVersion,
      qualifiers: <String, Object?>{
        'owner': userId.trim(),
      },
    );
  }
}

class AnswerKeyExamTypeQuery {
  const AnswerKeyExamTypeQuery({
    required this.userId,
    required this.examType,
  });

  final String userId;
  final String examType;

  String buildScopeId({
    required int schemaVersion,
  }) {
    return CacheScopeNamespace.buildQueryScope(
      userId: userId,
      limit: 0,
      scopeTag: 'exam_type',
      schemaVersion: schemaVersion,
      qualifiers: <String, Object?>{
        'examType': examType.trim(),
      },
    );
  }
}

AnswerKeySnapshotRepository? _maybeFindAnswerKeySnapshotRepository() {
  final isRegistered = Get.isRegistered<AnswerKeySnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<AnswerKeySnapshotRepository>();
}

AnswerKeySnapshotRepository _ensureAnswerKeySnapshotRepository() {
  final existing = _maybeFindAnswerKeySnapshotRepository();
  if (existing != null) return existing;
  return Get.put(AnswerKeySnapshotRepository(), permanent: true);
}

CacheFirstCoordinator<List<BookletModel>> _createAnswerKeySnapshotCoordinator(
  AnswerKeySnapshotRepository repository,
) {
  return CacheFirstCoordinator<List<BookletModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<BookletModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<BookletModel>>(
      prefsPrefix: 'answer_key_snapshot_v1',
      encode: repository._encodeItems,
      decode: repository._decodeItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<BookletModel>>(),
    policy: CacheFirstPolicyRegistry.policyForSurface(
      _answerKeyHomeSurfaceKey,
    ),
  );
}

EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>
    _createAnswerKeyHomeAdapter(AnswerKeySnapshotRepository repository) {
  return EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>(
    surfaceKey: _answerKeyHomeSurfaceKey,
    coordinator: repository._coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => repository._bookletRepository.fetchByIds(docIds),
    loadWarmSnapshot: repository._loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      _answerKeyHomeSurfaceKey,
    ),
  );
}

EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>
    _createAnswerKeySearchAdapter(AnswerKeySnapshotRepository repository) {
  return EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>(
    surfaceKey: _answerKeySearchSurfaceKey,
    coordinator: repository._coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => repository._bookletRepository.fetchByIds(docIds),
    loadWarmSnapshot: repository._loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      _answerKeySearchSurfaceKey,
    ),
  );
}

CacheFirstQueryPipeline<AnswerKeyOwnerQuery, List<BookletModel>,
    List<BookletModel>> _createAnswerKeyOwnerPipeline(
  AnswerKeySnapshotRepository repository,
) {
  return CacheFirstQueryPipeline<AnswerKeyOwnerQuery, List<BookletModel>,
      List<BookletModel>>(
    surfaceKey: _answerKeyOwnerSurfaceKey,
    coordinator: repository._coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        _answerKeyOwnerSurfaceKey,
      ),
    ),
    fetchRaw: _fetchAnswerKeyOwnerItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      _answerKeyOwnerSurfaceKey,
    ),
  );
}

CacheFirstQueryPipeline<AnswerKeyExamTypeQuery, List<BookletModel>,
    List<BookletModel>> _createAnswerKeyTypePipeline(
  AnswerKeySnapshotRepository repository,
) {
  return CacheFirstQueryPipeline<AnswerKeyExamTypeQuery, List<BookletModel>,
      List<BookletModel>>(
    surfaceKey: _answerKeyTypeSurfaceKey,
    coordinator: repository._coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        _answerKeyTypeSurfaceKey,
      ),
    ),
    fetchRaw: _fetchAnswerKeyTypeItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      _answerKeyTypeSurfaceKey,
    ),
  );
}

Future<List<BookletModel>> _fetchAnswerKeyOwnerItems(
  AnswerKeyOwnerQuery query,
) async {
  final normalizedUserId = query.userId.trim();
  if (normalizedUserId.isEmpty) return const <BookletModel>[];
  final snapshot = await AppFirestore.instance
      .collection('books')
      .where('userID', isEqualTo: normalizedUserId)
      .get(const GetOptions(source: Source.serverAndCache));
  final items = snapshot.docs
      .map((doc) => BookletModel.fromMap(doc.data(), doc.id))
      .toList(growable: false)
    ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
  return items;
}

Future<List<BookletModel>> _fetchAnswerKeyTypeItems(
  AnswerKeyExamTypeQuery query,
) async {
  final normalizedExamType = query.examType.trim();
  if (normalizedExamType.isEmpty) return const <BookletModel>[];
  final snapshot = await AppFirestore.instance
      .collection('books')
      .where('sinavTuru', isEqualTo: normalizedExamType)
      .get(const GetOptions(source: Source.serverAndCache));
  final items = snapshot.docs
      .map((doc) => BookletModel.fromMap(doc.data(), doc.id))
      .toList(growable: false)
    ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
  return items;
}
