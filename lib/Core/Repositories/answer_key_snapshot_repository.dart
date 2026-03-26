import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

part 'answer_key_snapshot_repository_facade_part.dart';
part 'answer_key_snapshot_repository_support_part.dart';
part 'answer_key_snapshot_repository_runtime_part.dart';

class AnswerKeySnapshotRepository extends GetxService {
  AnswerKeySnapshotRepository();

  static const String _homeSurfaceKey = 'answer_key_home_snapshot';
  static const String _searchSurfaceKey = 'answer_key_search_snapshot';

  static AnswerKeySnapshotRepository? maybeFind() =>
      _maybeFindAnswerKeySnapshotRepository();

  static AnswerKeySnapshotRepository ensure() =>
      _ensureAnswerKeySnapshotRepository();

  final BookletRepository _bookletRepository = BookletRepository.ensure();

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
