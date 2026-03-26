part of 'short_repository.dart';

ShortRepository? maybeFindShortRepository() => _maybeFindShortRepository();

ShortRepository ensureShortRepository() => _ensureShortRepository();

ShortRepository? _maybeFindShortRepository() =>
    Get.isRegistered<ShortRepository>() ? Get.find<ShortRepository>() : null;

ShortRepository _ensureShortRepository() =>
    _maybeFindShortRepository() ?? Get.put(ShortRepository(), permanent: true);

extension ShortRepositoryFacadePart on ShortRepository {
  Future<ShortPageResult> fetchReadyPage({
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
    int pageSize = 20,
    int? nowMs,
  }) =>
      _fetchReadyPageImpl(
        startAfter: startAfter,
        pageSize: pageSize,
        nowMs: nowMs,
      );

  Future<List<PostsModel>> fetchRandomReadyPosts({
    int limit = 1000,
    int? nowMs,
  }) =>
      _fetchRandomReadyShortPosts(this, limit: limit, nowMs: nowMs);

  Future<PostsModel?> fetchById(
    String docId, {
    bool preferCache = true,
  }) =>
      _fetchShortById(docId, preferCache: preferCache);

  Future<Map<String, PostsModel>> fetchByIds(
    List<String> postIds, {
    bool preferCache = true,
  }) =>
      _fetchShortByIds(postIds, preferCache: preferCache);
}

Future<List<PostsModel>> _fetchRandomReadyShortPosts(
  ShortRepository repository, {
  int limit = 1000,
  int? nowMs,
}) async {
  final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
  final snap = await repository._firestore
      .collection('Posts')
      .where('hlsStatus', isEqualTo: 'ready')
      .limit(limit)
      .get();
  return snap.docs
      .map(PostsModel.fromFirestore)
      .where((p) => p.timeStamp <= ts)
      .toList(growable: false);
}

Future<PostsModel?> _fetchShortById(
  String docId, {
  bool preferCache = true,
}) async {
  final map = await PostRepository.ensure().fetchPostCardsByIds(
    <String>[docId],
    preferCache: preferCache,
  );
  return map[docId];
}

Future<Map<String, PostsModel>> _fetchShortByIds(
  List<String> postIds, {
  bool preferCache = true,
}) {
  return PostRepository.ensure().fetchPostCardsByIds(
    postIds,
    preferCache: preferCache,
  );
}
