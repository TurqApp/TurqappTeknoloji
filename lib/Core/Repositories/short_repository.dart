import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'short_repository_models_part.dart';
part 'short_repository_facade_part.dart';
part 'short_repository_query_part.dart';

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
