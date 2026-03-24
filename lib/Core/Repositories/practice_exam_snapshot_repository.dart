import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

part 'practice_exam_snapshot_repository_query_part.dart';
part 'practice_exam_snapshot_repository_codec_part.dart';

class PracticeExamSnapshotRepository extends GetxService {
  PracticeExamSnapshotRepository();

  static const String _homeSurfaceKey = 'practice_exam_home_snapshot';
  static const String _searchSurfaceKey = 'practice_exam_search_snapshot';

  static PracticeExamSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<PracticeExamSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<PracticeExamSnapshotRepository>();
  }

  static PracticeExamSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(PracticeExamSnapshotRepository(), permanent: true);
  }

  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();

  late final CacheFirstCoordinator<List<SinavModel>> _coordinator =
      CacheFirstCoordinator<List<SinavModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<SinavModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<SinavModel>>(
      prefsPrefix: 'practice_exam_snapshot_v1',
      encode: _encodeItems,
      decode: _decodeItems,
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

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _homeAdapter = EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => _practiceExamRepository.fetchByIds(docIds),
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
  );

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _searchAdapter =
      EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => _practiceExamRepository.fetchByIds(docIds),
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
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
    int limit = 40,
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
    int limit = 40,
    bool forceSync = false,
  }) =>
      _searchImpl(
        query: query,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );
}
