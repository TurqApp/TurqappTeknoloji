import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Models/posts_model.dart';

class ShortPageResult {
  const ShortPageResult({
    required this.posts,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<PostsModel> posts;
  final QueryDocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

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
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final base = _firestore.collection('Posts');

    Query<Map<String, dynamic>> query = base
        .where('hlsStatus', isEqualTo: 'ready')
        .where('arsiv', isEqualTo: false)
        .where('deletedPost', isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('timeStamp', descending: true)
        .limit(pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await PerformanceService.traceFeedLoad(
        () => query.get(),
        feedMode: 'short_page',
      );
    } catch (e) {
      final isIndexError = e is FirebaseException
          ? e.code == 'failed-precondition'
          : e.toString().contains('requires an index');
      if (!isIndexError) rethrow;

      Query<Map<String, dynamic>> fallback = base
          .where('arsiv', isEqualTo: false)
          .where('deletedPost', isEqualTo: false)
          .where('timeStamp', isLessThanOrEqualTo: ts)
          .orderBy('timeStamp', descending: true)
          .limit(pageSize);
      if (startAfter != null) {
        fallback = fallback.startAfterDocument(startAfter);
      }
      try {
        snap = await fallback.get();
      } catch (_) {
        Query<Map<String, dynamic>> broad =
            base.orderBy('timeStamp', descending: true).limit(pageSize);
        if (startAfter != null) {
          broad = broad.startAfterDocument(startAfter);
        }
        snap = await broad.get();
      }
    }

    if (snap.docs.isEmpty) {
      return ShortPageResult(
        posts: const <PostsModel>[],
        lastDoc: startAfter,
        hasMore: false,
      );
    }

    return ShortPageResult(
      posts: snap.docs
          .map((d) => PostsModel.fromMap(d.data(), d.id))
          .toList(growable: false),
      lastDoc: snap.docs.last,
      hasMore: snap.docs.length == pageSize,
    );
  }

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
