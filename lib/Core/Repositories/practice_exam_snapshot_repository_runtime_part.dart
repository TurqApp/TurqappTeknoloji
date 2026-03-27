part of 'practice_exam_snapshot_repository.dart';

const String _practiceExamHomeSurfaceKey = 'practice_exam_home_snapshot';
const String _practiceExamSearchSurfaceKey = 'practice_exam_search_snapshot';

class PracticeExamSnapshotRepository extends GetxService {
  PracticeExamSnapshotRepository();

  final PracticeExamRepository _practiceExamRepository =
      ensurePracticeExamRepository();

  late final CacheFirstCoordinator<List<SinavModel>> _coordinator =
      _buildPracticeExamSnapshotCoordinator();

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _homeAdapter = _buildPracticeExamSnapshotAdapter(
    surfaceKey: _practiceExamHomeSurfaceKey,
    coordinator: _coordinator,
    repository: _practiceExamRepository,
  );

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _searchAdapter = _buildPracticeExamSnapshotAdapter(
    surfaceKey: _practiceExamSearchSurfaceKey,
    coordinator: _coordinator,
    repository: _practiceExamRepository,
  );
}

CacheFirstCoordinator<List<SinavModel>>
    _buildPracticeExamSnapshotCoordinator() {
  return CacheFirstCoordinator<List<SinavModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<SinavModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<SinavModel>>(
      prefsPrefix: 'practice_exam_snapshot_v1',
      encode: _encodePracticeExamSnapshotItems,
      decode: _decodePracticeExamSnapshotItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<SinavModel>>(),
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

EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
    _buildPracticeExamSnapshotAdapter({
  required String surfaceKey,
  required CacheFirstCoordinator<List<SinavModel>> coordinator,
  required PracticeExamRepository repository,
}) {
  return EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>(
    surfaceKey: surfaceKey,
    coordinator: coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => repository.fetchByIds(docIds),
    loadWarmSnapshot: (query) => _loadPracticeExamWarmSnapshot(
      repository,
      query,
    ),
    isEmpty: (items) => items.isEmpty,
  );
}

Future<List<SinavModel>?> _loadPracticeExamWarmSnapshot(
  PracticeExamRepository repository,
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
  final items = await repository.fetchByIds(
    docIds,
    cacheOnly: true,
  );
  return items.isEmpty ? null : items;
}
