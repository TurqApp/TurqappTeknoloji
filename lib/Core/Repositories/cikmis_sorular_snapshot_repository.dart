import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cikmis_sorular_repository.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';

class CikmisSorularSnapshotRepository extends GetxService {
  CikmisSorularSnapshotRepository();

  static const String _homeSurfaceKey = 'past_question_home_snapshot';

  static CikmisSorularSnapshotRepository? maybeFind() {
    final isRegistered = Get.isRegistered<CikmisSorularSnapshotRepository>();
    if (!isRegistered) return null;
    return Get.find<CikmisSorularSnapshotRepository>();
  }

  static CikmisSorularSnapshotRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(CikmisSorularSnapshotRepository(), permanent: true);
  }

  final CikmisSorularRepository _repository = CikmisSorularRepository.ensure();

  late final CacheFirstCoordinator<List<Map<String, dynamic>>> _coordinator =
      CacheFirstCoordinator<List<Map<String, dynamic>>>(
    memoryStore: MemoryScopedSnapshotStore<List<Map<String, dynamic>>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<Map<String, dynamic>>>(
      prefsPrefix: 'past_question_snapshot_v3',
      encode: _encodeDocs,
      decode: _decodeDocs,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<Map<String, dynamic>>>(),
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
          List<Map<String, dynamic>>> _homePipeline =
      CacheFirstQueryPipeline<String, List<Map<String, dynamic>>,
          List<Map<String, dynamic>>>(
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
  }) async* {
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty) {
      yield const CachedResource<List<Map<String, dynamic>>>(
        data: <Map<String, dynamic>>[],
        hasLocalSnapshot: false,
        isRefreshing: false,
        isStale: false,
        hasLiveError: false,
        snapshotAt: null,
        source: CachedResourceSource.none,
      );
      return;
    }

    try {
      final docs = await _repository.fetchRootDocs(
        preferCache: !forceSync,
        forceRefresh: forceSync,
      );
      yield CachedResource<List<Map<String, dynamic>>>(
        data: _filterSearchDocs(docs, normalizedQuery, limit: limit),
        hasLocalSnapshot: !forceSync,
        isRefreshing: false,
        isStale: false,
        hasLiveError: false,
        snapshotAt: DateTime.now(),
        source: forceSync
            ? CachedResourceSource.server
            : CachedResourceSource.scopedDisk,
      );
    } catch (error, stackTrace) {
      yield CachedResource<List<Map<String, dynamic>>>(
        data: const <Map<String, dynamic>>[],
        hasLocalSnapshot: false,
        isRefreshing: false,
        isStale: false,
        hasLiveError: true,
        snapshotAt: null,
        source: CachedResourceSource.none,
        liveError: error,
        liveErrorStackTrace: stackTrace,
      );
    }
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

  List<Map<String, dynamic>> _filterSearchDocs(
    List<Map<String, dynamic>> docs,
    String query, {
    required int limit,
  }) {
    final terms = query
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
    if (terms.isEmpty) return const <Map<String, dynamic>>[];

    return docs.where((doc) {
      final haystack = [
        doc['anaBaslik'],
        doc['sinavTuru'],
        doc['yil'],
        doc['baslik2'],
        doc['baslik3'],
        doc['dil'],
        doc['title'],
        doc['subtitle'],
        doc['description'],
      ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');
      return terms.every(haystack.contains);
    }).take(limit).map(Map<String, dynamic>.from).toList(growable: false);
  }
}
