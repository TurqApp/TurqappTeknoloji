part of 'profile_repository_library.dart';

extension ProfileRepositoryCachePart on ProfileRepository {
  Future<ProfileBuckets?> _readCachedBucketsImpl(String uid) async {
    if (uid.isEmpty) return null;
    final readDecision = MetadataReadPolicy.profilePosts();
    final fromMemory = _memory[uid];
    if (fromMemory != null) return fromMemory;
    if (!readDecision.readOrder.contains(MetadataReadSource.sharedPrefs)) {
      return null;
    }
    final all = await _cacheService.readBucket(uid: uid, bucket: 'all');
    final photos = await _cacheService.readBucket(uid: uid, bucket: 'photos');
    final videos = await _cacheService.readBucket(uid: uid, bucket: 'videos');
    final scheduled =
        await _cacheService.readBucket(uid: uid, bucket: 'scheduled');
    if (all.isEmpty && photos.isEmpty && videos.isEmpty && scheduled.isEmpty) {
      return null;
    }
    final buckets = ProfileBuckets(
      all: List<PostsModel>.from(all),
      photos: List<PostsModel>.from(photos),
      videos: List<PostsModel>.from(videos),
      scheduled: List<PostsModel>.from(scheduled),
    );
    _memory[uid] = buckets;
    return buckets;
  }

  Future<void> _writeBucketsImpl(String uid, ProfileBuckets buckets) async {
    if (uid.isEmpty) return;
    _memory[uid] = ProfileBuckets(
      all: List<PostsModel>.from(buckets.all),
      photos: List<PostsModel>.from(buckets.photos),
      videos: List<PostsModel>.from(buckets.videos),
      scheduled: List<PostsModel>.from(buckets.scheduled),
    );
    await Future.wait([
      _cacheService.writeBucket(uid: uid, bucket: 'all', posts: buckets.all),
      _cacheService.writeBucket(
        uid: uid,
        bucket: 'photos',
        posts: buckets.photos,
      ),
      _cacheService.writeBucket(
        uid: uid,
        bucket: 'videos',
        posts: buckets.videos,
      ),
      _cacheService.writeBucket(
        uid: uid,
        bucket: 'scheduled',
        posts: buckets.scheduled,
      ),
    ]);
  }

  Future<void> _removePostFromCachesImpl({
    required String uid,
    required String docId,
  }) async {
    if (uid.isEmpty || docId.isEmpty) return;

    final buckets = _memory[uid];
    if (buckets != null) {
      _memory[uid] = ProfileBuckets(
        all: buckets.all.where((post) => post.docID != docId).toList(),
        photos: buckets.photos.where((post) => post.docID != docId).toList(),
        videos: buckets.videos.where((post) => post.docID != docId).toList(),
        scheduled:
            buckets.scheduled.where((post) => post.docID != docId).toList(),
      );
    }

    final archive = _archiveMemory[uid];
    if (archive != null) {
      _archiveMemory[uid] =
          archive.where((post) => post.docID != docId).toList();
    }

    if (_latestPostMemory[uid]?.docID == docId) {
      _latestPostMemory.remove(uid);
    }
    if (_latestResharePostMemory[uid]?.docID == docId) {
      _latestResharePostMemory.remove(uid);
    }

    await _cacheService.removePost(uid: uid, docId: docId);
  }

  Future<List<PostsModel>> _readCachedArchiveImpl(String uid) async {
    if (uid.isEmpty) return const <PostsModel>[];
    final fromMemory = _archiveMemory[uid];
    if (fromMemory != null) return List<PostsModel>.from(fromMemory);
    final archive = await _cacheService.readBucket(uid: uid, bucket: 'archive');
    if (archive.isEmpty) return const <PostsModel>[];
    _archiveMemory[uid] = List<PostsModel>.from(archive);
    return archive;
  }

  Future<void> _writeArchiveImpl(String uid, List<PostsModel> posts) async {
    if (uid.isEmpty) return;
    _archiveMemory[uid] = List<PostsModel>.from(posts);
    await _cacheService.writeBucket(uid: uid, bucket: 'archive', posts: posts);
  }

  Future<void> _clearUserImpl(String uid) async {
    _memory.remove(uid);
    _archiveMemory.remove(uid);
    _latestPostMemory.remove(uid);
    _latestResharePostMemory.remove(uid);
    await _cacheService.clearUser(uid);
  }
}
