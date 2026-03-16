import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';

class ExploreQueryPage {
  const ExploreQueryPage({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });

  final List<PostsModel> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class ExploreRepository extends GetxService {
  ExploreRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static ExploreRepository ensure() {
    if (Get.isRegistered<ExploreRepository>()) {
      return Get.find<ExploreRepository>();
    }
    return Get.put(ExploreRepository(), permanent: true);
  }

  Future<ExploreQueryPage> fetchExplorePostsPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 20,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('timeStamp', descending: true)
        .limit(pageLimit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQuery(
      query,
      pageLimit: pageLimit,
      feedMode: 'explore_posts',
    );
  }

  Future<ExploreQueryPage> fetchVideoReadyPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 30,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('hlsStatus', isEqualTo: 'ready')
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('timeStamp', descending: true)
        .limit(pageLimit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQuery(
      query,
      pageLimit: pageLimit,
      feedMode: 'explore_video',
    );
  }

  Future<ExploreQueryPage> fetchVideoFallbackPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 30,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('timeStamp', descending: true)
        .limit(pageLimit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQuery(
      query,
      pageLimit: pageLimit,
      feedMode: 'explore_video_fallback',
    );
  }

  Future<ExploreQueryPage> fetchVideoBroadPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 30,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('timeStamp', descending: true)
        .limit(pageLimit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQuery(
      query,
      pageLimit: pageLimit,
      feedMode: 'explore_video_broad',
    );
  }

  Future<ExploreQueryPage> fetchPhotoPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 20,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('video', isEqualTo: '')
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('timeStamp', descending: true)
        .limit(pageLimit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQuery(
      query,
      pageLimit: pageLimit,
      feedMode: 'explore_photo',
    );
  }

  Future<ExploreQueryPage> fetchFloodServerPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 60,
  }) async {
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('floodCount', isGreaterThan: 1)
        .orderBy('floodCount')
        .orderBy('timeStamp', descending: true)
        .limit(pageLimit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQuery(
      query,
      pageLimit: pageLimit,
      feedMode: 'explore_flood',
    );
  }

  Future<ExploreQueryPage> fetchFloodFallbackPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 60,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('timeStamp', descending: true)
        .limit(pageLimit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQuery(
      query,
      pageLimit: pageLimit,
      feedMode: 'explore_flood_fallback',
    );
  }

  Future<Map<String, PostsModel>> fetchPostsByIds(
    List<String> postIds, {
    bool preferCache = true,
  }) {
    return PostRepository.ensure().fetchPostCardsByIds(
      postIds,
      preferCache: preferCache,
    );
  }

  Future<ExploreQueryPage> _runPageQuery(
    Query<Map<String, dynamic>> query, {
    required int pageLimit,
    required String feedMode,
  }) async {
    final snap = await PerformanceService.traceFeedLoad(
      () => query.get(),
      feedMode: feedMode,
    );
    final postIds = snap.docs.map((doc) => doc.id).toList(growable: false);
    final byId = await fetchPostsByIds(postIds, preferCache: true);
    final items = postIds
        .map((id) => byId[id])
        .whereType<PostsModel>()
        .toList(growable: false);
    return ExploreQueryPage(
      items: items,
      lastDoc: snap.docs.isEmpty ? null : snap.docs.last,
      hasMore: snap.docs.length >= pageLimit,
    );
  }
}
