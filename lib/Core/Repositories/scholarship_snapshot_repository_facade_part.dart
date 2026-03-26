part of 'scholarship_snapshot_repository.dart';

ScholarshipSnapshotRepository? maybeFindScholarshipSnapshotRepository() {
  final isRegistered = Get.isRegistered<ScholarshipSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<ScholarshipSnapshotRepository>();
}

ScholarshipSnapshotRepository ensureScholarshipSnapshotRepository() {
  final existing = maybeFindScholarshipSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(ScholarshipSnapshotRepository(), permanent: true);
}

extension ScholarshipSnapshotRepositoryFacadePart
    on ScholarshipSnapshotRepository {
  Stream<CachedResource<ScholarshipListingSnapshot>> openHome({
    required String userId,
    int limit = ReadBudgetRegistry.scholarshipHomeInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) =>
      _openHomeImpl(
        userId: userId,
        limit: limit,
        page: page,
        forceSync: forceSync,
      );

  Future<CachedResource<ScholarshipListingSnapshot>> loadHome({
    required String userId,
    int limit = ReadBudgetRegistry.scholarshipHomeInitialLimit,
    int page = 1,
    bool forceSync = false,
  }) =>
      _loadHomeImpl(
        userId: userId,
        limit: limit,
        page: page,
        forceSync: forceSync,
      );

  Stream<CachedResource<ScholarshipListingSnapshot>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    int page = 1,
    bool forceSync = false,
  }) =>
      _openSearchImpl(
        query: query,
        userId: userId,
        limit: limit,
        page: page,
        forceSync: forceSync,
      );

  Future<CachedResource<ScholarshipListingSnapshot>> search({
    required String query,
    required String userId,
    int limit = 40,
    int page = 1,
    bool forceSync = false,
  }) =>
      _searchImpl(
        query: query,
        userId: userId,
        limit: limit,
        page: page,
        forceSync: forceSync,
      );
}
