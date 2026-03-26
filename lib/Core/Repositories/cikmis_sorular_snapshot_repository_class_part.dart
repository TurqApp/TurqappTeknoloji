part of 'cikmis_sorular_snapshot_repository.dart';

class CikmisSorularSnapshotRepository extends GetxService {
  CikmisSorularSnapshotRepository();

  static const String _homeSurfaceKey = 'past_question_home_snapshot';

  static CikmisSorularSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<CikmisSorularSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<CikmisSorularSnapshotRepository>();
  }

  static CikmisSorularSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(CikmisSorularSnapshotRepository(), permanent: true);
  }

  final CikmisSorularRepository _repository = CikmisSorularRepository.ensure();

  late final CacheFirstCoordinator<List<Map<String, dynamic>>> _coordinator =
      CacheFirstCoordinator<List<Map<String, dynamic>>>(
    memoryStore: MemoryScopedSnapshotStore<List<Map<String, dynamic>>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<Map<String, dynamic>>>(
      prefsPrefix: 'past_question_snapshot_v3',
      encode: _encodeDocs,
      decode: _decodeDocs,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<Map<String, dynamic>>>(),
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

  late final CacheFirstQueryPipeline<String, List<Map<String, dynamic>>,
          List<Map<String, dynamic>>> _homePipeline =
      CacheFirstQueryPipeline<String, List<Map<String, dynamic>>,
          List<Map<String, dynamic>>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (userId) => userId,
    scopeIdBuilder: (_) => 'home',
    fetchRaw: (_) => _repository.fetchRootDocs(preferCache: false),
    resolve: (docs) => docs,
    loadWarmSnapshot: (_) => _repository.fetchRootDocs(cacheOnly: true),
    isEmpty: (docs) => docs.isEmpty,
    liveSource: CachedResourceSource.server,
  );

  Map<String, dynamic> _encodeDocs(List<Map<String, dynamic>> docs) =>
      encodePastQuestionSnapshotDocs(docs);

  List<Map<String, dynamic>> _decodeDocs(Map<String, dynamic> json) =>
      decodePastQuestionSnapshotDocs(json);
}
