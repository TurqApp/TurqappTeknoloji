import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/practice_exam_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Modules/Education/PracticeExams/sinav_model.dart';

class PracticeExamSnapshotRepository extends GetxService {
  PracticeExamSnapshotRepository();

  static const String _homeSurfaceKey = 'practice_exam_home_snapshot';
  static const String _searchSurfaceKey = 'practice_exam_search_snapshot';

  static PracticeExamSnapshotRepository ensure() {
    if (Get.isRegistered<PracticeExamSnapshotRepository>()) {
      return Get.find<PracticeExamSnapshotRepository>();
    }
    return Get.put(PracticeExamSnapshotRepository(), permanent: true);
  }

  final PracticeExamRepository _practiceExamRepository =
      PracticeExamRepository.ensure();

  late final CacheFirstCoordinator<List<SinavModel>> _coordinator =
      CacheFirstCoordinator<List<SinavModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<SinavModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<SinavModel>>(
      prefsPrefix: 'practice_exam_snapshot_v1',
      encode: _encodeItems,
      decode: _decodeItems,
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

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _homeAdapter =
      EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => _practiceExamRepository.fetchByIds(docIds),
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
  );

  late final EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>
      _searchAdapter =
      EducationTypesenseDocIdHydrationAdapter<List<SinavModel>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    fetchDocIds: EducationTypesenseDocIdHydrationAdapter.defaultFetchDocIds,
    hydrate: (docIds) => _practiceExamRepository.fetchByIds(docIds),
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
  );

  Stream<CachedResource<List<SinavModel>>> openHome({
    required String userId,
    int limit = 30,
    bool forceSync = false,
  }) {
    return _homeAdapter.open(
      EducationTypesenseDocIdQuery(
        entity: EducationTypesenseEntity.practiceExam,
        query: '*',
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'home',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> loadHome({
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

  Stream<CachedResource<List<SinavModel>>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseDocIdQuery(
        entity: EducationTypesenseEntity.practiceExam,
        query: query,
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<SinavModel>>> search({
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

  Future<List<SinavModel>?> _loadWarmSnapshot(
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
    final items = await _practiceExamRepository.fetchByIds(
      docIds,
      cacheOnly: true,
    );
    return items.isEmpty ? null : items;
  }

  Map<String, dynamic> _encodeItems(List<SinavModel> items) {
    return <String, dynamic>{
      'items': items
          .map(
            (item) => <String, dynamic>{
              'docID': item.docID,
              'cover': item.cover,
              'sinavTuru': item.sinavTuru,
              'timeStamp': item.timeStamp,
              'sinavAciklama': item.sinavAciklama,
              'sinavAdi': item.sinavAdi,
              'kpssSecilenLisans': item.kpssSecilenLisans,
              'dersler': item.dersler,
              'taslak': item.taslak,
              'public': item.public,
              'userID': item.userID,
              'soruSayilari': item.soruSayilari,
              'bitis': item.bitis,
              'bitisDk': item.bitisDk,
            },
          )
          .toList(growable: false),
    };
  }

  List<SinavModel> _decodeItems(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
          return SinavModel(
            docID: (item['docID'] ?? '').toString(),
            cover: (item['cover'] ?? '').toString(),
            sinavTuru: (item['sinavTuru'] ?? '').toString(),
            timeStamp: item['timeStamp'] is num
                ? item['timeStamp'] as num
                : num.tryParse((item['timeStamp'] ?? '0').toString()) ?? 0,
            sinavAciklama: (item['sinavAciklama'] ?? '').toString(),
            sinavAdi: (item['sinavAdi'] ?? '').toString(),
            kpssSecilenLisans: (item['kpssSecilenLisans'] ?? '').toString(),
            dersler: (item['dersler'] is List)
                ? (item['dersler'] as List)
                    .map((value) => value.toString())
                    .toList(growable: false)
                : const <String>[],
            taslak: item['taslak'] == true,
            public: item['public'] != false,
            userID: (item['userID'] ?? '').toString(),
            soruSayilari: (item['soruSayilari'] is List)
                ? (item['soruSayilari'] as List)
                    .map((value) => value.toString())
                    .toList(growable: false)
                : const <String>[],
            bitis: item['bitis'] is num
                ? item['bitis'] as num
                : num.tryParse((item['bitis'] ?? '0').toString()) ?? 0,
            bitisDk: item['bitisDk'] is num
                ? item['bitisDk'] as num
                : num.tryParse((item['bitisDk'] ?? '0').toString()) ?? 0,
          );
        })
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }
}
