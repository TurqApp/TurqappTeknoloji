part of 'practice_exam_snapshot_repository.dart';

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
