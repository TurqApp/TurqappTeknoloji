import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';

import '../../Core/Services/profile_posts_cache_service.dart';
import '../../Models/posts_model.dart';
import 'post_repository.dart';

part 'profile_repository_cache_part.dart';
part 'profile_repository_query_part.dart';

class ProfileBuckets {
  const ProfileBuckets({
    required this.all,
    required this.photos,
    required this.videos,
    required this.scheduled,
  });

  final List<PostsModel> all;
  final List<PostsModel> photos;
  final List<PostsModel> videos;
  final List<PostsModel> scheduled;
}

class ProfilePageResult extends ProfileBuckets {
  const ProfilePageResult({
    required super.all,
    required super.photos,
    required super.videos,
    required super.scheduled,
    required this.lastDoc,
    required this.hasMore,
  });

  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;
}

class ProfileRepository extends GetxService {
  ProfileRepository({
    FirebaseFirestore? firestore,
    ProfilePostsCacheService? cacheService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _cacheService = cacheService ?? ProfilePostsCacheService();

  final FirebaseFirestore _firestore;
  final ProfilePostsCacheService _cacheService;
  final PostRepository _postRepository = PostRepository.ensure();
  final Map<String, ProfileBuckets> _memory = <String, ProfileBuckets>{};
  final Map<String, List<PostsModel>> _archiveMemory =
      <String, List<PostsModel>>{};
  final Map<String, PostsModel?> _latestPostMemory = <String, PostsModel?>{};
  final Map<String, PostsModel?> _latestResharePostMemory =
      <String, PostsModel?>{};

  static ProfileRepository? maybeFind() {
    final isRegistered = Get.isRegistered<ProfileRepository>();
    if (!isRegistered) return null;
    return Get.find<ProfileRepository>();
  }

  static ProfileRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileRepository(), permanent: true);
  }

  Future<ProfileBuckets?> readCachedBuckets(String uid) =>
      _readCachedBucketsImpl(uid);

  Future<void> writeBuckets(String uid, ProfileBuckets buckets) =>
      _writeBucketsImpl(uid, buckets);

  Future<ProfilePageResult> fetchPrimaryPage({
    required String uid,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 24,
  }) =>
      _fetchPrimaryPageImpl(
        uid: uid,
        startAfter: startAfter,
        limit: limit,
      );

  Future<PostsModel?> fetchLatestProfilePost(String uid) =>
      _fetchLatestProfilePostImpl(uid);

  Future<PostsModel?> fetchLatestResharePost(String uid) =>
      _fetchLatestResharePostImpl(uid);

  void invalidateLatestResharePost(String uid) {
    if (uid.isEmpty) return;
    _latestResharePostMemory.remove(uid);
  }

  Future<void> removePostFromCaches({
    required String uid,
    required String docId,
  }) =>
      _removePostFromCachesImpl(
        uid: uid,
        docId: docId,
      );

  Future<List<PostsModel>> readCachedArchive(String uid) =>
      _readCachedArchiveImpl(uid);

  Future<void> writeArchive(String uid, List<PostsModel> posts) =>
      _writeArchiveImpl(uid, posts);

  Future<List<PostsModel>> fetchArchive(String uid) => _fetchArchiveImpl(uid);

  Future<void> clearUser(String uid) => _clearUserImpl(uid);

  ProfileBuckets buildBucketsFromPosts(List<PostsModel> posts) =>
      _buildBucketsFromPostsImpl(posts);
}
