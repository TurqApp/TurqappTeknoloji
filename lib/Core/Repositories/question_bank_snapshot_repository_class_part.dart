part of 'question_bank_snapshot_repository.dart';

class QuestionBankSnapshotRepository extends GetxService {
  QuestionBankSnapshotRepository();

  static const String _searchSurfaceKey = 'workout_search_snapshot';

  static QuestionBankSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<QuestionBankSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<QuestionBankSnapshotRepository>();
  }

  static QuestionBankSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(QuestionBankSnapshotRepository(), permanent: true);
  }

  late final CacheFirstCoordinator<List<QuestionBankModel>> _coordinator =
      CacheFirstCoordinator<List<QuestionBankModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<QuestionBankModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<QuestionBankModel>>(
      prefsPrefix: 'workout_snapshot_v1',
      encode: _encodeQuestionBankItems,
      decode: _decodeQuestionBankItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<QuestionBankModel>>(),
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

  late final EducationTypesenseCacheFirstAdapter<List<QuestionBankModel>>
      _searchAdapter =
      EducationTypesenseCacheFirstAdapter<List<QuestionBankModel>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    resolve: (raw) => raw.hits
        .map(QuestionBankModel.fromTypesenseHit)
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false),
    loadWarmSnapshot: _loadWarmQuestionBankSnapshot,
    isEmpty: (items) => items.isEmpty,
  );
}
