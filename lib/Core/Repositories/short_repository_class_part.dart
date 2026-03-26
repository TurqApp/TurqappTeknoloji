part of 'short_repository.dart';

class ShortRepository extends GetxService {
  ShortRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static ShortRepository? maybeFind() => _maybeFindShortRepository();

  static ShortRepository ensure() => _ensureShortRepository();

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
