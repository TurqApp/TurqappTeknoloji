part of 'tutoring_snapshot_repository.dart';

class TutoringSnapshotRepository extends GetxService {
  TutoringSnapshotRepository();

  static const String _homeSurfaceKey = 'tutoring_home_snapshot';
  static const String _searchSurfaceKey = 'tutoring_search_snapshot';

  static TutoringSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<TutoringSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<TutoringSnapshotRepository>();
  }

  static TutoringSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(TutoringSnapshotRepository(), permanent: true);
  }

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  late final CacheFirstCoordinator<List<TutoringModel>> _coordinator =
      _buildTutoringSnapshotCoordinator();

  late final EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
      _homeAdapter = _buildTutoringSnapshotAdapter(
    repository: this,
    surfaceKey: _homeSurfaceKey,
  );

  late final EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
      _searchAdapter = _buildTutoringSnapshotAdapter(
    repository: this,
    surfaceKey: _searchSurfaceKey,
  );
}
