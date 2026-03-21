import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/booklet_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Models/Education/booklet_model.dart';

class AnswerKeySnapshotRepository extends GetxService {
  AnswerKeySnapshotRepository();

  static const String _homeSurfaceKey = 'answer_key_home_snapshot';
  static const String _searchSurfaceKey = 'answer_key_search_snapshot';

  static AnswerKeySnapshotRepository? maybeFind() {
    if (!Get.isRegistered<AnswerKeySnapshotRepository>()) return null;
    return Get.find<AnswerKeySnapshotRepository>();
  }

  static AnswerKeySnapshotRepository _ensureService() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(AnswerKeySnapshotRepository(), permanent: true);
  }

  static AnswerKeySnapshotRepository ensure() => _ensureService();

  final BookletRepository _bookletRepository = BookletRepository.ensure();

  late final CacheFirstCoordinator<List<BookletModel>> _coordinator =
      CacheFirstCoordinator<List<BookletModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<BookletModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<BookletModel>>(
      prefsPrefix: 'answer_key_snapshot_v1',
      encode: _encodeItems,
      decode: _decodeItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<BookletModel>>(),
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

  late final EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>
      _homeAdapter =
      EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => _bookletRepository.fetchByIds(docIds),
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
  );

  late final EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>
      _searchAdapter =
      EducationTypesenseDocIdHydrationAdapter<List<BookletModel>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => _bookletRepository.fetchByIds(docIds),
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
  );

  Stream<CachedResource<List<BookletModel>>> openHome({
    required String userId,
    int limit = 30,
    bool forceSync = false,
  }) {
    return _homeAdapter.open(
      EducationTypesenseDocIdQuery(
        entity: EducationTypesenseEntity.answerKey,
        query: '*',
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'home',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<BookletModel>>> loadHome({
    required String userId,
    int limit = 30,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<BookletModel>>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseDocIdQuery(
        entity: EducationTypesenseEntity.answerKey,
        query: query,
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<BookletModel>>> search({
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

  Future<List<BookletModel>?> _loadWarmSnapshot(
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
    final docIds = raw.hits
        .map((hit) => (hit['docId'] ?? hit['id'] ?? '').toString().trim())
        .where((id) => id.isNotEmpty)
        .toList(growable: false);
    if (docIds.isEmpty) return null;
    final items = await _bookletRepository.fetchByIds(
      docIds,
      cacheOnly: true,
    );
    return items.isEmpty ? null : items;
  }

  Map<String, dynamic> _encodeItems(List<BookletModel> items) {
    return <String, dynamic>{
      'items': items
          .map(
            (item) => <String, dynamic>{
              'docID': item.docID,
              'basimTarihi': item.basimTarihi,
              'baslik': item.baslik,
              'cover': item.cover,
              'dil': item.dil,
              'kaydet': item.kaydet,
              'sinavTuru': item.sinavTuru,
              'timeStamp': item.timeStamp,
              'yayinEvi': item.yayinEvi,
              'userID': item.userID,
              'viewCount': item.viewCount,
            },
          )
          .toList(growable: false),
    };
  }

  List<BookletModel> _decodeItems(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
          return BookletModel(
            dil: (item['dil'] ?? '').toString(),
            sinavTuru: (item['sinavTuru'] ?? '').toString(),
            cover: (item['cover'] ?? '').toString(),
            baslik: (item['baslik'] ?? '').toString(),
            timeStamp: item['timeStamp'] is num
                ? item['timeStamp'] as num
                : num.tryParse((item['timeStamp'] ?? '0').toString()) ?? 0,
            docID: (item['docID'] ?? '').toString(),
            kaydet: (item['kaydet'] is List)
                ? (item['kaydet'] as List)
                    .map((value) => value.toString())
                    .toList(growable: false)
                : const <String>[],
            basimTarihi: (item['basimTarihi'] ?? '').toString(),
            yayinEvi: (item['yayinEvi'] ?? '').toString(),
            userID: (item['userID'] ?? '').toString(),
            viewCount: item['viewCount'] is num
                ? (item['viewCount'] as num).toInt()
                : int.tryParse((item['viewCount'] ?? '0').toString()) ?? 0,
          );
        })
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }
}
