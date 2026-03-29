part of 'cikmis_sorular_snapshot_repository.dart';

Stream<CachedResource<List<Map<String, dynamic>>>> openPastQuestionSearch(
  CikmisSorularSnapshotRepository repository, {
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
    final resource = forceSync
        ? await repository.loadHome(
            userId: userId,
            forceSync: true,
          )
        : await repository.loadCachedHome(userId: userId);
    final docs = resource.data ?? const <Map<String, dynamic>>[];
    yield CachedResource<List<Map<String, dynamic>>>(
      data: filterPastQuestionSearchDocs(docs, normalizedQuery, limit: limit),
      hasLocalSnapshot: resource.hasLocalSnapshot,
      isRefreshing: false,
      isStale: resource.isStale,
      hasLiveError: resource.hasLiveError,
      snapshotAt: resource.snapshotAt,
      source: resource.source,
      liveError: resource.liveError,
      liveErrorStackTrace: resource.liveErrorStackTrace,
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

Map<String, dynamic> encodePastQuestionSnapshotDocs(
  List<Map<String, dynamic>> docs,
) {
  return <String, dynamic>{
    'items': docs
        .map((doc) => Map<String, dynamic>.from(doc))
        .toList(growable: false),
  };
}

List<Map<String, dynamic>> decodePastQuestionSnapshotDocs(
  Map<String, dynamic> json,
) {
  final rawItems = (json['items'] as List<dynamic>?) ?? const <dynamic>[];
  return rawItems
      .whereType<Map>()
      .map((raw) => Map<String, dynamic>.from(raw.cast<dynamic, dynamic>()))
      .where((item) => (item['_docId'] ?? '').toString().isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> filterPastQuestionSearchDocs(
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

  return docs
      .where((doc) {
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
      })
      .take(limit)
      .map(Map<String, dynamic>.from)
      .toList(growable: false);
}
