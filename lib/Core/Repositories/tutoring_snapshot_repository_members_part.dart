part of 'tutoring_snapshot_repository.dart';

mixin _TutoringSnapshotRepositoryMembersPart on GetxService {
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  late final CacheFirstCoordinator<List<TutoringModel>> _coordinator =
      _buildTutoringSnapshotCoordinator();

  late final EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
      _homeAdapter = _buildTutoringSnapshotAdapter(
    repository: this as TutoringSnapshotRepository,
    surfaceKey: TutoringSnapshotRepository._homeSurfaceKey,
  );

  late final EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
      _searchAdapter = _buildTutoringSnapshotAdapter(
    repository: this as TutoringSnapshotRepository,
    surfaceKey: TutoringSnapshotRepository._searchSurfaceKey,
  );
}
