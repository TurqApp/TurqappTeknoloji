part of 'practice_exam_snapshot_repository.dart';

class PracticeExamSnapshotRepository extends GetxService {
  PracticeExamSnapshotRepository();

  static const String _homeSurfaceKey = 'practice_exam_home_snapshot';
  static const String _searchSurfaceKey = 'practice_exam_search_snapshot';

  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();

  late final CacheFirstCoordinator<List<SinavModel>> _coordinator =
      _buildPracticeExamSnapshotCoordinator();

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _homeAdapter = _buildPracticeExamSnapshotAdapter(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    repository: _practiceExamRepository,
  );

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _searchAdapter = _buildPracticeExamSnapshotAdapter(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    repository: _practiceExamRepository,
  );
}
