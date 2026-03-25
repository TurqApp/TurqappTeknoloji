part of 'job_home_snapshot_repository.dart';

extension _JobHomeSnapshotRepositoryDataX on JobHomeSnapshotRepository {
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
