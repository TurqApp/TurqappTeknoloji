part of 'profile_repository_library.dart';

ProfileRepository? maybeFindProfileRepository() {
  final isRegistered = Get.isRegistered<ProfileRepository>();
  if (!isRegistered) return null;
  return Get.find<ProfileRepository>();
}

ProfileRepository ensureProfileRepository() {
  final existing = maybeFindProfileRepository();
  if (existing != null) return existing;
  return Get.put(ProfileRepository(), permanent: true);
}

extension ProfileRepositoryFacadePart on ProfileRepository {
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

  void invalidateLatestProfilePost(String uid) {
    if (uid.isEmpty) return;
    _latestPostMemory.remove(uid);
  }

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
