part of 'tutoring_snapshot_repository.dart';

class TutoringSnapshotRepository extends GetxService {
  TutoringSnapshotRepository();

  static const String _homeSurfaceKey = 'tutoring_home_snapshot';
  static const String _searchSurfaceKey = 'tutoring_search_snapshot';
  static const String _ownerSurfaceKey = 'tutoring_owner_snapshot';

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  late final CacheFirstCoordinator<List<TutoringModel>> _coordinator =
      _buildTutoringSnapshotCoordinator();

  late final EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
      _homeAdapter = _buildTutoringSnapshotAdapter(
    repository: this,
    surfaceKey: TutoringSnapshotRepository._homeSurfaceKey,
  );

  late final EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
      _searchAdapter = _buildTutoringSnapshotAdapter(
    repository: this,
    surfaceKey: TutoringSnapshotRepository._searchSurfaceKey,
  );

  late final CacheFirstQueryPipeline<TutoringOwnerQuery, List<TutoringModel>,
          List<TutoringModel>> _ownerPipeline =
      CacheFirstQueryPipeline<TutoringOwnerQuery, List<TutoringModel>,
          List<TutoringModel>>(
    surfaceKey: TutoringSnapshotRepository._ownerSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (query) => query.userId.trim(),
    scopeIdBuilder: (query) => query.buildScopeId(
      schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
        TutoringSnapshotRepository._ownerSurfaceKey,
      ),
    ),
    fetchRaw: _fetchTutoringOwnerItems,
    resolve: (items) => items,
    isEmpty: (items) => items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(
      TutoringSnapshotRepository._ownerSurfaceKey,
    ),
  );
}

class TutoringOwnerQuery {
  const TutoringOwnerQuery({
    required this.userId,
  });

  final String userId;

  String buildScopeId({
    required int schemaVersion,
  }) {
    return CacheScopeNamespace.buildQueryScope(
      userId: userId,
      limit: 0,
      scopeTag: 'owner',
      schemaVersion: schemaVersion,
      qualifiers: <String, Object?>{
        'owner': userId.trim(),
      },
    );
  }
}

CacheFirstCoordinator<List<TutoringModel>> _buildTutoringSnapshotCoordinator() {
  return CacheFirstCoordinator<List<TutoringModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<TutoringModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<TutoringModel>>(
      prefsPrefix: 'tutoring_snapshot_v1',
      encode: _encodeTutoringSnapshots,
      decode: _decodeTutoringSnapshots,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<TutoringModel>>(),
    policy: CacheFirstPolicyRegistry.policyForSurface(
      TutoringSnapshotRepository._homeSurfaceKey,
    ),
  );
}

EducationTypesenseCacheFirstAdapter<List<TutoringModel>>
    _buildTutoringSnapshotAdapter({
  required TutoringSnapshotRepository repository,
  required String surfaceKey,
}) {
  return EducationTypesenseCacheFirstAdapter<List<TutoringModel>>(
    surfaceKey: surfaceKey,
    coordinator: repository._coordinator,
    resolve: (raw) => _resolveTutoringHits(repository, raw.hits),
    loadWarmSnapshot: _loadWarmTutoringSnapshot,
    isEmpty: (items) => items.isEmpty,
    schemaVersion: CacheFirstPolicyRegistry.schemaVersionForSurface(surfaceKey),
  );
}

Future<List<TutoringModel>> _fetchTutoringOwnerItems(
  TutoringOwnerQuery query,
) async {
  final normalizedUserId = query.userId.trim();
  if (normalizedUserId.isEmpty) return const <TutoringModel>[];
  final snapshot = await AppFirestore.instance
      .collection('educators')
      .where('userID', isEqualTo: normalizedUserId)
      .get(const GetOptions(source: Source.serverAndCache));
  final items = snapshot.docs
      .map((doc) => TutoringModel.fromJson(doc.data(), doc.id))
      .where((item) => item.docID.isNotEmpty)
      .toList(growable: false)
    ..sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
  return items;
}
