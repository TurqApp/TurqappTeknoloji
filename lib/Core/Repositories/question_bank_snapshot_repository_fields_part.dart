part of 'question_bank_snapshot_repository.dart';

const String _questionBankSearchSurfaceKey = 'workout_search_snapshot';

class _QuestionBankSnapshotRepositoryState {
  late final CacheFirstCoordinator<List<QuestionBankModel>> coordinator =
      CacheFirstCoordinator<List<QuestionBankModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<QuestionBankModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<QuestionBankModel>>(
      prefsPrefix: 'workout_snapshot_v1',
      encode: _encodeQuestionBankItems,
      decode: _decodeQuestionBankItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<QuestionBankModel>>(),
    policy: CacheFirstPolicyRegistry.policyForSurface(
      _questionBankSearchSurfaceKey,
    ),
  );

  late final EducationTypesenseCacheFirstAdapter<List<QuestionBankModel>>
      searchAdapter =
      EducationTypesenseCacheFirstAdapter<List<QuestionBankModel>>(
    surfaceKey: _questionBankSearchSurfaceKey,
    coordinator: coordinator,
    resolve: (raw) => raw.hits
        .map(QuestionBankModel.fromTypesenseHit)
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false),
    loadWarmSnapshot: _loadWarmQuestionBankSnapshot,
    isEmpty: (items) => items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      _questionBankSearchSurfaceKey,
    ),
  );
}

extension QuestionBankSnapshotRepositoryFieldsPart
    on QuestionBankSnapshotRepository {
  CacheFirstCoordinator<List<QuestionBankModel>> get _coordinator =>
      _state.coordinator;

  EducationTypesenseCacheFirstAdapter<List<QuestionBankModel>>
      get _searchAdapter => _state.searchAdapter;
}
