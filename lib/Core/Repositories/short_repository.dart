import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

part 'short_repository_models_part.dart';
part 'short_repository_query_part.dart';

class ShortRepository extends GetxService {
  ShortRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static ShortRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ShortRepository>();
    if (!isRegistered) return null;
    return Get.find<ShortRepository>();
  }

  static ShortRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ShortRepository(), permanent: true);
  }

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
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final snap = await _firestore
        .collection('Posts')
        .where('hlsStatus', isEqualTo: 'ready')
        .limit(limit)
        .get();
    return snap.docs
        .map(PostsModel.fromFirestore)
        .where((p) => p.timeStamp <= ts)
        .toList(growable: false);
  }

  Future<PostsModel?> fetchById(
    String docId, {
    bool preferCache = true,
  }) async {
    final map = await PostRepository.ensure().fetchPostCardsByIds(
      <String>[docId],
      preferCache: preferCache,
    );
    return map[docId];
  }

  Future<Map<String, PostsModel>> fetchByIds(
    List<String> postIds, {
    bool preferCache = true,
  }) {
    return PostRepository.ensure().fetchPostCardsByIds(
      postIds,
      preferCache: preferCache,
    );
  }
}
