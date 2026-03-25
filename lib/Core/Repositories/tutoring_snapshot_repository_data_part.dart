part of 'tutoring_snapshot_repository.dart';

Future<List<TutoringModel>?> _loadWarmTutoringSnapshot(
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
  final items =
      _resolveTutoringHits(TutoringSnapshotRepository.ensure(), raw.hits);
  return items.isEmpty ? null : items;
}

List<TutoringModel> _resolveTutoringHits(
  TutoringSnapshotRepository repository,
  List<Map<String, dynamic>> hits,
) {
  return hits
      .map(TutoringModel.fromTypesenseHit)
      .where((item) => item.docID.isNotEmpty)
      .where((item) => item.ended != true)
      .map((item) {
    _primeTutoringUserSummary(repository, item);
    return item;
  }).toList(growable: false);
}

void _primeTutoringUserSummary(
  TutoringSnapshotRepository repository,
  TutoringModel item,
) {
  final userId = item.userID.trim();
  if (userId.isEmpty) return;
  final summary = repository._userSummaryResolver.resolveFromMaps(
    userId,
    embedded: <String, dynamic>{
      'nickname': item.nickname,
      'displayName': item.displayName,
      'avatarUrl': item.avatarUrl,
      'rozet': item.rozet,
    },
  );
  unawaited(repository._userSummaryResolver.seedRaw(userId, summary.toMap()));
}

Map<String, dynamic> _encodeTutoringSnapshots(List<TutoringModel> items) {
  return <String, dynamic>{
    'items': items
        .map((item) => <String, dynamic>{
              'docID': item.docID,
              ...item.toJson(),
            })
        .toList(growable: false),
  };
}

List<TutoringModel> _decodeTutoringSnapshots(Map<String, dynamic> json) {
  final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
  return rawItems
      .whereType<Map>()
      .map((raw) {
        final item = Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
        final docId = (item.remove('docID') ?? '').toString();
        return TutoringModel.fromJson(item, docId);
      })
      .where((item) => item.docID.isNotEmpty)
      .toList(growable: false);
}
