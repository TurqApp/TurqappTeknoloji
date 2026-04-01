part of 'answer_key_snapshot_repository.dart';

mixin _AnswerKeySnapshotRepositoryMembersPart on GetxService {
  final BookletRepository _bookletRepository = ensureBookletRepository();

  late final CacheFirstCoordinator<List<BookletModel>> _coordinator =
      _createAnswerKeySnapshotCoordinator(this as AnswerKeySnapshotRepository);

  late final EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>
      _homeAdapter = _createAnswerKeyHomeAdapter(
    this as AnswerKeySnapshotRepository,
  );

  late final EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>
      _searchAdapter = _createAnswerKeySearchAdapter(
    this as AnswerKeySnapshotRepository,
  );

  late final CacheFirstQueryPipeline<AnswerKeyOwnerQuery, List<BookletModel>,
          List<BookletModel>> _ownerPipeline =
      _createAnswerKeyOwnerPipeline(this as AnswerKeySnapshotRepository);

  late final CacheFirstQueryPipeline<AnswerKeyExamTypeQuery, List<BookletModel>,
          List<BookletModel>> _typePipeline =
      _createAnswerKeyTypePipeline(this as AnswerKeySnapshotRepository);

  Future<List<BookletModel>?> _loadWarmSnapshot(
    EducationTypesenseDocIdQuery query,
  ) =>
      _AnswerKeySnapshotRepositoryRuntimeX(
        this as AnswerKeySnapshotRepository,
      )._loadWarmSnapshot(query);

  Map<String, dynamic> _encodeItems(List<BookletModel> items) =>
      _AnswerKeySnapshotRepositoryRuntimeX(
        this as AnswerKeySnapshotRepository,
      )._encodeItems(items);

  List<BookletModel> _decodeItems(Map<String, dynamic> json) =>
      _AnswerKeySnapshotRepositoryRuntimeX(
        this as AnswerKeySnapshotRepository,
      )._decodeItems(json);
}
