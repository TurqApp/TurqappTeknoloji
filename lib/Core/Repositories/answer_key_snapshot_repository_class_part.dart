part of 'answer_key_snapshot_repository.dart';

class AnswerKeySnapshotRepository extends GetxService {
  AnswerKeySnapshotRepository();

  final BookletRepository _bookletRepository = ensureBookletRepository();

  late final CacheFirstCoordinator<List<BookletModel>> _coordinator =
      _createAnswerKeySnapshotCoordinator(this);

  late final EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>
      _homeAdapter = _createAnswerKeyHomeAdapter(this);

  late final EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>
      _searchAdapter = _createAnswerKeySearchAdapter(this);

  Future<List<BookletModel>?> _loadWarmSnapshot(
    EducationTypesenseDocIdQuery query,
  ) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this)._loadWarmSnapshot(query);

  Map<String, dynamic> _encodeItems(List<BookletModel> items) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this)._encodeItems(items);

  List<BookletModel> _decodeItems(Map<String, dynamic> json) =>
      _AnswerKeySnapshotRepositoryRuntimeX(this)._decodeItems(json);
}
