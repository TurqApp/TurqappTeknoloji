part of 'answer_key_snapshot_repository.dart';

const String _answerKeyHomeSurfaceKey = 'answer_key_home_snapshot';
const String _answerKeySearchSurfaceKey = 'answer_key_search_snapshot';

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
    policy: const CacheFirstPolicy(
      snapshotTtl: Duration(minutes: 20),
      minLiveSyncInterval: Duration(seconds: 30),
      syncOnOpen: true,
      allowWarmLaunchFallback: true,
      persistWarmLaunchSnapshot: true,
      treatWarmLaunchAsStale: true,
      preservePreviousOnEmptyLive: true,
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
  );
}
