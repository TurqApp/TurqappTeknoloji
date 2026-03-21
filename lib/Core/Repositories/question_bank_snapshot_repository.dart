import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Models/Education/question_bank_model.dart';

class QuestionBankSnapshotRepository extends GetxService {
  QuestionBankSnapshotRepository();

  static const String _searchSurfaceKey = 'workout_search_snapshot';

  static QuestionBankSnapshotRepository _ensureService() {
    if (Get.isRegistered<QuestionBankSnapshotRepository>()) {
      return Get.find<QuestionBankSnapshotRepository>();
    }
    return Get.put(QuestionBankSnapshotRepository(), permanent: true);
  }

  static QuestionBankSnapshotRepository ensure() {
    return _ensureService();
  }

  late final CacheFirstCoordinator<List<QuestionBankModel>> _coordinator =
      CacheFirstCoordinator<List<QuestionBankModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<QuestionBankModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<QuestionBankModel>>(
      prefsPrefix: 'workout_snapshot_v1',
      encode: _encodeItems,
      decode: _decodeItems,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<QuestionBankModel>>(),
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

  late final EducationTypesenseCacheFirstAdapter<List<QuestionBankModel>>
      _searchAdapter =
      EducationTypesenseCacheFirstAdapter<List<QuestionBankModel>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    resolve: (raw) => raw.hits
        .map(QuestionBankModel.fromTypesenseHit)
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false),
    loadWarmSnapshot: _loadWarmSnapshot,
    isEmpty: (items) => items.isEmpty,
  );

  Stream<CachedResource<List<QuestionBankModel>>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.workout,
        query: query,
        limit: limit,
        page: 1,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<QuestionBankModel>>> search({
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

  Future<List<QuestionBankModel>> fetchCategoryPoolDocs(
    String anaBaslik,
    String sinavTuru,
    String ders, {
    int? limit,
  }) async {
    final filterBy = <String>[
      'active:=true',
      'anaBaslik:=${_typesenseFilterValue(anaBaslik)}',
      'sinavTuru:=${_typesenseFilterValue(sinavTuru)}',
      'ders:=${_typesenseFilterValue(ders)}',
    ].join(' && ');

    final docs = <QuestionBankModel>[];
    final perPage = limit == null ? 250 : limit.clamp(1, 250);
    var page = 1;

    while (true) {
      final result = await TypesenseEducationSearchService.instance.searchHits(
        entity: EducationTypesenseEntity.workout,
        query: '*',
        limit: perPage,
        page: page,
        filterBy: filterBy,
        sortBy: 'seq:asc',
      );
      docs.addAll(
        result.hits.map(QuestionBankModel.fromTypesenseHit),
      );
      if (limit != null && docs.length >= limit) {
        break;
      }
      if (result.hits.length < perPage) {
        break;
      }
      page += 1;
    }

    return limit == null ? docs : docs.take(limit).toList(growable: false);
  }

  Future<List<QuestionBankModel>?> _loadWarmSnapshot(
    EducationTypesenseQuery query,
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
    final items = raw.hits
        .map(QuestionBankModel.fromTypesenseHit)
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
    return items.isEmpty ? null : items;
  }

  String _typesenseFilterValue(String value) =>
      '`${value.trim().replaceAll('`', r'\`')}`';

  Map<String, dynamic> _encodeItems(List<QuestionBankModel> items) {
    return <String, dynamic>{
      'items': items.map((item) => item.toJson()).toList(growable: false),
    };
  }

  List<QuestionBankModel> _decodeItems(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map(
            (raw) => QuestionBankModel.fromJson(Map<String, dynamic>.from(raw)))
        .where((item) => item.docID.isNotEmpty)
        .toList(growable: false);
  }
}
