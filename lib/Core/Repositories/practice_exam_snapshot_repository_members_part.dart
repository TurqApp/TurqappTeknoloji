part of 'practice_exam_snapshot_repository.dart';

const String _practiceExamHomeSurfaceKey = 'practice_exam_home_snapshot';
const String _practiceExamSearchSurfaceKey = 'practice_exam_search_snapshot';

class PracticeExamSnapshotRepository extends GetxService
    with _PracticeExamSnapshotRepositoryMembersPart {
  PracticeExamSnapshotRepository();
}

mixin _PracticeExamSnapshotRepositoryMembersPart on GetxService {
  final PracticeExamRepository _practiceExamRepository =
      ensurePracticeExamRepository();

  late final CacheFirstCoordinator<List<SinavModel>> _coordinator =
      _buildPracticeExamSnapshotCoordinator();

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _homeAdapter = _buildPracticeExamSnapshotAdapter(
    surfaceKey: _practiceExamHomeSurfaceKey,
    coordinator: _coordinator,
    repository: _practiceExamRepository,
  );

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _searchAdapter = _buildPracticeExamSnapshotAdapter(
    surfaceKey: _practiceExamSearchSurfaceKey,
    coordinator: _coordinator,
    repository: _practiceExamRepository,
  );
}
