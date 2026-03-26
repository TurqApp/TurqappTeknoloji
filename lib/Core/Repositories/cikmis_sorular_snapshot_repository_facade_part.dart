part of 'cikmis_sorular_snapshot_repository.dart';

CikmisSorularSnapshotRepository? maybeFindCikmisSorularSnapshotRepository() {
  final isRegistered = Get.isRegistered<CikmisSorularSnapshotRepository>();
  if (!isRegistered) return null;
  return Get.find<CikmisSorularSnapshotRepository>();
}

CikmisSorularSnapshotRepository ensureCikmisSorularSnapshotRepository() {
  final existing = maybeFindCikmisSorularSnapshotRepository();
  if (existing != null) return existing;
  return Get.put(CikmisSorularSnapshotRepository(), permanent: true);
}

extension CikmisSorularSnapshotRepositoryFacadePart
    on CikmisSorularSnapshotRepository {
  Stream<CachedResource<List<Map<String, dynamic>>>> openHome({
    required String userId,
    bool forceSync = false,
  }) {
    return _homePipeline.open(userId, forceSync: forceSync);
  }

  Future<CachedResource<List<Map<String, dynamic>>>> loadHome({
    required String userId,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<Map<String, dynamic>>>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) =>
      openPastQuestionSearch(
        this,
        query: query,
        userId: userId,
        limit: limit,
        forceSync: forceSync,
      );

  Future<CachedResource<List<Map<String, dynamic>>>> search({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return openSearch(
      query: query,
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }
}
