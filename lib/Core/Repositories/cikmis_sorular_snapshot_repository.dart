import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';

class CikmisSorularSnapshotRepository extends GetxService {
  CikmisSorularSnapshotRepository();

  static const String _homeSurfaceKey = 'past_question_home_snapshot';
  static const String _searchSurfaceKey = 'past_question_search_snapshot';

  static CikmisSorularSnapshotRepository ensure() {
    if (Get.isRegistered<CikmisSorularSnapshotRepository>()) {
      return Get.find<CikmisSorularSnapshotRepository>();
    }
    return Get.put(CikmisSorularSnapshotRepository(), permanent: true);
  }

  final CikmisSorularRepository _repository = CikmisSorularRepository.ensure();

  late final CacheFirstCoordinator<List<Map<String, dynamic>>> _coordinator =
      CacheFirstCoordinator<List<Map<String, dynamic>>>(
    memoryStore: MemoryScopedSnapshotStore<List<Map<String, dynamic>>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<Map<String, dynamic>>>(
      prefsPrefix: 'past_question_snapshot_v1',
      encode: _encodeDocs,
      decode: _decodeDocs,
    ),
    policy: const CacheFirstPolicy(
      snapshotTtl: Duration(minutes: 20),
      minLiveSyncInterval: Duration(seconds: 30),
      syncOnOpen: true,
      allowWarmLaunchFallback: true,
      persistWarmLaunchSnapshot: true,
      treatWarmLaunchAsStale: true,
      preservePreviousOnEmptyLive: true,
    ),
  );

  late final CacheFirstQueryPipeline<String, List<Map<String, dynamic>>,
      List<Map<String, dynamic>>> _homePipeline = CacheFirstQueryPipeline<
          String, List<Map<String, dynamic>>, List<Map<String, dynamic>>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    userIdResolver: (userId) => userId,
    scopeIdBuilder: (_) => 'home',
    fetchRaw: (_) => _repository.fetchRootDocs(preferCache: false),
    resolve: (docs) => docs,
    loadWarmSnapshot: (_) => _repository.fetchRootDocs(cacheOnly: true),
    isEmpty: (docs) => docs.isEmpty,
    liveSource: CachedResourceSource.server,
  );

  late final EducationTypesenseDocIdHydrationAdapter<List<Map<String, dynamic>>>
      _searchAdapter =
      EducationTypesenseDocIdHydrationAdapter<List<Map<String, dynamic>>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => _repository.fetchRootDocsByIds(docIds),
    loadWarmSnapshot: _loadWarmSearchSnapshot,
    isEmpty: (docs) => docs.isEmpty,
  );

  Stream<CachedResource<List<Map<String, dynamic>>>> openHome({
    required String userId,
    bool forceSync = false,
  }) {
    return _homePipeline.open(userId, forceSync: forceSync);
  }

  Future<CachedResource<List<Map<String, dynamic>>>> loadHome({
    required String userId,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<Map<String, dynamic>>>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseDocIdQuery(
        entity: EducationTypesenseEntity.pastQuestion,
        query: query,
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<Map<String, dynamic>>>> search({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return openSearch(
      query: query,
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Future<List<Map<String, dynamic>>?> _loadWarmSearchSnapshot(
    EducationTypesenseDocIdQuery query,
  ) async {
    final raw = await TypesenseEducationSearchService.instance.searchHits(
      entity: query.entity,
      query: query.query,
      limit: query.limit,
      page: query.page,
      filterBy: query.filterBy,
      sortBy: query.sortBy,
      cacheOnly: true,
    );
    final docs = raw.hits
        .map(_docFromHit)
        .where((doc) => (doc['_docId'] ?? '').toString().isNotEmpty)
        .toList(growable: false);
    return docs.isEmpty ? null : docs;
  }

  Map<String, dynamic> _encodeDocs(List<Map<String, dynamic>> docs) {
    return <String, dynamic>{
      'items': docs
          .map((doc) => Map<String, dynamic>.from(doc))
          .toList(growable: false),
    };
  }

  List<Map<String, dynamic>> _decodeDocs(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) => Map<String, dynamic>.from(raw.cast<dynamic, dynamic>()))
        .where((item) => (item['_docId'] ?? '').toString().isNotEmpty)
        .toList(growable: false);
  }

  Map<String, dynamic> _docFromHit(Map<String, dynamic> hit) {
    return <String, dynamic>{
      '_docId': (hit['docId'] ?? hit['id'] ?? '').toString(),
      'anaBaslik': (hit['anaBaslik'] ?? '').toString(),
      'sinavTuru': (hit['sinavTuru'] ?? '').toString(),
      'yil': (hit['yil'] ?? '').toString(),
      'baslik2': (hit['baslik2'] ?? '').toString(),
      'baslik3': (hit['baslik3'] ?? '').toString(),
      'dil': (hit['dil'] ?? '').toString(),
      'sira': (hit['seq'] as num?)?.toInt() ?? 0,
      'title': (hit['title'] ?? '').toString(),
      'subtitle': (hit['subtitle'] ?? '').toString(),
      'description': (hit['description'] ?? '').toString(),
      'cover': (hit['cover'] ?? '').toString(),
      'timeStamp': hit['timeStamp'] ?? 0,
    };
  }
}
