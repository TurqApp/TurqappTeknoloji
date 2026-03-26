part of 'cikmis_sorular_snapshot_repository.dart';

class CikmisSorularSnapshotRepository extends GetxService {
  CikmisSorularSnapshotRepository();

  static const String _homeSurfaceKey = 'past_question_home_snapshot';

  final CikmisSorularRepository _repository = ensureCikmisSorularRepository();

  late final CacheFirstCoordinator<List<Map<String, dynamic>>> _coordinator =
      _buildPastQuestionCoordinator(this);

  late final CacheFirstQueryPipeline<String, List<Map<String, dynamic>>,
          List<Map<String, dynamic>>> _homePipeline =
      _buildPastQuestionHomePipeline(this);

  Map<String, dynamic> _encodeDocs(List<Map<String, dynamic>> docs) =>
      encodePastQuestionSnapshotDocs(docs);

  List<Map<String, dynamic>> _decodeDocs(Map<String, dynamic> json) =>
      decodePastQuestionSnapshotDocs(json);
}
