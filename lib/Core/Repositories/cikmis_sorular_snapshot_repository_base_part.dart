part of 'cikmis_sorular_snapshot_repository.dart';

const String _pastQuestionHomeSnapshotSurfaceKey =
    'past_question_home_snapshot';

abstract class _CikmisSorularSnapshotRepositoryBase extends GetxService {
  final CikmisSorularRepository _repository = ensureCikmisSorularRepository();

  late final CacheFirstCoordinator<List<Map<String, dynamic>>> _coordinator =
      _buildPastQuestionCoordinator(this as CikmisSorularSnapshotRepository);

  late final CacheFirstQueryPipeline<String, List<Map<String, dynamic>>,
          List<Map<String, dynamic>>> _homePipeline =
      _buildPastQuestionHomePipeline(this as CikmisSorularSnapshotRepository);

  Map<String, dynamic> _encodeDocs(List<Map<String, dynamic>> docs) =>
      encodePastQuestionSnapshotDocs(docs);

  List<Map<String, dynamic>> _decodeDocs(Map<String, dynamic> json) =>
      decodePastQuestionSnapshotDocs(json);
}
