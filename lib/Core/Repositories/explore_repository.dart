import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/performance_service.dart';
import 'package:turqappv2/Models/posts_model.dart';
import 'package:turqappv2/Core/Repositories/post_repository.dart';

part 'explore_repository_query_part.dart';
part 'explore_repository_page_part.dart';

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

  static ExploreRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ExploreRepository>();
    if (!isRegistered) return null;
    return Get.find<ExploreRepository>();
  }

  static ExploreRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ExploreRepository(), permanent: true);
  }

  Future<ExploreQueryPage> fetchExplorePostsPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 20,
    int? nowMs,
  }) =>
      _fetchExplorePostsPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<ExploreQueryPage> fetchVideoReadyPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 30,
    int? nowMs,
  }) =>
      _fetchVideoReadyPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<ExploreQueryPage> fetchVideoFallbackPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 30,
    int? nowMs,
  }) =>
      _fetchVideoFallbackPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<ExploreQueryPage> fetchVideoBroadPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 30,
    int? nowMs,
  }) =>
      _fetchVideoBroadPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<ExploreQueryPage> fetchPhotoPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 20,
    int? nowMs,
  }) =>
      _fetchPhotoPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<ExploreQueryPage> fetchFloodServerPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 60,
  }) =>
      _fetchFloodServerPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
      );

  Future<ExploreQueryPage> fetchFloodFallbackPage({
    DocumentSnapshot? startAfter,
    int pageLimit = 60,
    int? nowMs,
  }) =>
      _fetchFloodFallbackPageImpl(
        startAfter: startAfter,
        pageLimit: pageLimit,
        nowMs: nowMs,
      );

  Future<Map<String, PostsModel>> fetchPostsByIds(
    List<String> postIds, {
    bool preferCache = true,
  }) {
    return PostRepository.ensure().fetchPostCardsByIds(
      postIds,
      preferCache: preferCache,
    );
  }
}
