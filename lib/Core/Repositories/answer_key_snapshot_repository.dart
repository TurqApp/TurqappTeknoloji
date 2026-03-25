import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

part 'answer_key_snapshot_repository_runtime_part.dart';

class AnswerKeySnapshotRepository extends GetxService {
  AnswerKeySnapshotRepository();

  static const String _homeSurfaceKey = 'answer_key_home_snapshot';
  static const String _searchSurfaceKey = 'answer_key_search_snapshot';

  static AnswerKeySnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<AnswerKeySnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<AnswerKeySnapshotRepository>();
  }

  static AnswerKeySnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AnswerKeySnapshotRepository(), permanent: true);
  }

  final BookletRepository _bookletRepository = BookletRepository.ensure();

  late final CacheFirstCoordinator<List<BookletModel>> _coordinator =
      CacheFirstCoordinator<List<BookletModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<BookletModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<BookletModel>>(
      prefsPrefix: 'answer_key_snapshot_v1',
      encode: _encodeItems,
      decode: _decodeItems,
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

  late final EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>
      _homeAdapter =
      EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => _bookletRepository.fetchByIds(docIds),
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
  );

  late final EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>
      _searchAdapter =
      EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => _bookletRepository.fetchByIds(docIds),
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
  );

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

  Future<List<BookletModel>?> _loadWarmSnapshot(
    EducationTypesenseDocIdQuery query,
  ) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this)._loadWarmSnapshot(query);

  Map<String, dynamic> _encodeItems(List<BookletModel> items) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this)._encodeItems(items);

  List<BookletModel> _decodeItems(Map<String, dynamic> json) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this)._decodeItems(json);
}
