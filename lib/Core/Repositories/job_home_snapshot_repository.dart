import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/typesense_education_service.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/job_model.dart';

class JobHomeSnapshotRepository extends GetxService {
  JobHomeSnapshotRepository();

  static const String _homeSurfaceKey = 'jobs_home_snapshot';
  static const String _searchSurfaceKey = 'jobs_search_snapshot';

  static JobHomeSnapshotRepository _ensureService() {
    if (Get.isRegistered<JobHomeSnapshotRepository>()) {
      return Get.find<JobHomeSnapshotRepository>();
    }
    return Get.put(JobHomeSnapshotRepository(), permanent: true);
  }

  static JobHomeSnapshotRepository ensure() => _ensureService();

  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();

  late final CacheFirstCoordinator<List<JobModel>> _coordinator =
      CacheFirstCoordinator<List<JobModel>>(
    memoryStore: MemoryScopedSnapshotStore<List<JobModel>>(),
    snapshotStore: SharedPrefsScopedSnapshotStore<List<JobModel>>(
      prefsPrefix: 'job_home_snapshot_v1',
      encode: _encodeJobs,
      decode: _decodeJobs,
    ),
    telemetry: const CacheFirstKpiTelemetry<List<JobModel>>(),
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

  late final EducationTypesenseCacheFirstAdapter<List<JobModel>> _homeAdapter =
      EducationTypesenseCacheFirstAdapter<List<JobModel>>(
    surfaceKey: _homeSurfaceKey,
    coordinator: _coordinator,
    resolve: (raw) => _resolveHits(raw.hits),
    loadWarmSnapshot: _loadWarmEducationSnapshot,
    isEmpty: (jobs) => jobs.isEmpty,
  );

  late final EducationTypesenseCacheFirstAdapter<List<JobModel>>
      _searchAdapter = EducationTypesenseCacheFirstAdapter<List<JobModel>>(
    surfaceKey: _searchSurfaceKey,
    coordinator: _coordinator,
    resolve: (raw) => _resolveHits(raw.hits),
    loadWarmSnapshot: _loadWarmEducationSnapshot,
    isEmpty: (jobs) => jobs.isEmpty,
  );

  Stream<CachedResource<List<JobModel>>> openHome({
    required String userId,
    int limit = 150,
    bool forceSync = false,
  }) {
    return _homeAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.job,
        query: '*',
        limit: limit,
        userId: userId,
        scopeTag: 'home',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<JobModel>>> loadHome({
    required String userId,
    int limit = 150,
    bool forceSync = false,
  }) {
    return openHome(
      userId: userId,
      limit: limit,
      forceSync: forceSync,
    ).last;
  }

  Stream<CachedResource<List<JobModel>>> openSearch({
    required String query,
    required String userId,
    int limit = 40,
    bool forceSync = false,
  }) {
    return _searchAdapter.open(
      EducationTypesenseQuery(
        entity: EducationTypesenseEntity.job,
        query: query,
        limit: limit,
        userId: userId,
        scopeTag: 'search',
      ),
      forceSync: forceSync,
    );
  }

  Future<CachedResource<List<JobModel>>> search({
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

  Future<List<JobModel>?> _loadWarmEducationSnapshot(
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
    final jobs = _resolveHits(raw.hits);
    return jobs.isEmpty ? null : jobs;
  }

  List<JobModel> _resolveHits(List<Map<String, dynamic>> hits) {
    final jobs = <JobModel>[];
    final seen = <String>{};
    for (final hit in hits) {
      final job = JobModel.fromTypesenseHit(hit);
      if (job.docID.isEmpty || seen.contains(job.docID) || job.ended) {
        continue;
      }
      seen.add(job.docID);
      _primeUserSummaryFromHit(job, hit);
      jobs.add(job);
    }
    return jobs;
  }

  void _primeUserSummaryFromHit(
    JobModel job,
    Map<String, dynamic> hit,
  ) {
    final userId = job.userID.trim();
    if (userId.isEmpty) return;
    final summary = _userSummaryResolver.resolveFromMaps(
      userId,
      embedded: <String, dynamic>{
        'nickname': hit['nickname'] ?? job.authorNickname,
        'username': hit['username'] ?? job.authorNickname,
        'displayName': hit['displayName'] ?? job.authorDisplayName,
        'avatarUrl': hit['avatarUrl'] ?? job.authorAvatarUrl,
        'rozet': hit['rozet'] ?? hit['badge'],
      },
    );
    unawaited(_userSummaryResolver.seedRaw(userId, summary.toMap()));
  }

  Map<String, dynamic> _encodeJobs(List<JobModel> jobs) {
    return <String, dynamic>{
      'items': jobs
          .map((job) => <String, dynamic>{
                'docID': job.docID,
                ...job.toMap(),
              })
          .toList(growable: false),
    };
  }

  List<JobModel> _decodeJobs(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
    return rawItems
        .whereType<Map>()
        .map((raw) {
          final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
          final docId = (item.remove('docID') ?? '').toString();
          return JobModel.fromMap(item, docId);
        })
        .where((job) => job.docID.isNotEmpty)
        .toList(growable: false);
  }
}
