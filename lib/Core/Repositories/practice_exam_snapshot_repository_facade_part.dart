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
