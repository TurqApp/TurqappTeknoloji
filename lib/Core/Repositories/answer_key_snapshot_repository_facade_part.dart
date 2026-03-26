part of 'answer_key_snapshot_repository.dart';

AnswerKeySnapshotRepository? maybeFindAnswerKeySnapshotRepository() =>
    _maybeFindAnswerKeySnapshotRepository();

AnswerKeySnapshotRepository ensureAnswerKeySnapshotRepository() =>
    _ensureAnswerKeySnapshotRepository();

extension AnswerKeySnapshotRepositoryFacadePart on AnswerKeySnapshotRepository {
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
}
