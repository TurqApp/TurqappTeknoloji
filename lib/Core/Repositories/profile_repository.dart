import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/PlaybackIntelligence/metadata_read_policy.dart';

import '../../Core/Services/profile_posts_cache_service.dart';
import '../../Models/posts_model.dart';
import 'post_repository.dart';

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
    if (!Get.isRegistered<ProfileRepository>()) return null;
    return Get.find<ProfileRepository>();
  }

  static ProfileRepository _ensureService() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(ProfileRepository(), permanent: true);
  }

  static ProfileRepository ensure() => _ensureService();

  Future<ProfileBuckets?> readCachedBuckets(String uid) async {
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

  Future<void> writeBuckets(String uid, ProfileBuckets buckets) async {
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

  Future<ProfilePageResult> fetchPrimaryPage({
    required String uid,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 24,
  }) async {
    var query = _firestore
        .collection('Posts')
        .where('userID', isEqualTo: uid)
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .orderBy('timeStamp', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot =
        await query.get(const GetOptions(source: Source.serverAndCache));
    final postIds = snapshot.docs.map((doc) => doc.id).toList(growable: false);
    final byId = await _postRepository.fetchPostCardsByIds(
      postIds,
      preferCache: true,
    );
    final buckets = buildBucketsFromPosts(
      postIds
          .map((id) => byId[id])
          .whereType<PostsModel>()
          .where((post) => post.deletedPost != true)
          .toList(growable: false),
    );
    return ProfilePageResult(
      all: buckets.all,
      photos: buckets.photos,
      videos: buckets.videos,
      scheduled: buckets.scheduled,
      lastDoc: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      hasMore: snapshot.docs.length >= limit,
    );
  }

  Future<PostsModel?> fetchLatestProfilePost(String uid) async {
    if (uid.isEmpty) return null;
    if (_latestPostMemory.containsKey(uid)) {
      return _latestPostMemory[uid];
    }

    final snapshot = await _firestore
        .collection('Posts')
        .where('userID', isEqualTo: uid)
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .orderBy('timeStamp', descending: true)
        .limit(1)
        .get(const GetOptions(source: Source.serverAndCache));

    if (snapshot.docs.isEmpty) {
      _latestPostMemory[uid] = null;
      return null;
    }

    final post = (await _postRepository.fetchPostCardsByIds(
      [snapshot.docs.first.id],
      preferCache: true,
    ))[snapshot.docs.first.id];
    _latestPostMemory[uid] = post;
    return post;
  }

  Future<PostsModel?> fetchLatestResharePost(String uid) async {
    if (uid.isEmpty) return null;
    if (_latestResharePostMemory.containsKey(uid)) {
      return _latestResharePostMemory[uid];
    }

    final snapshot = await _firestore
        .collection('users')
        .doc(uid)
        .collection('reshared_posts')
        .orderBy('timeStamp', descending: true)
        .limit(1)
        .get(const GetOptions(source: Source.serverAndCache));

    if (snapshot.docs.isEmpty) {
      _latestResharePostMemory[uid] = null;
      return null;
    }

    final postId = snapshot.docs.first.data()['post_docID'] as String?;
    if (postId == null || postId.isEmpty) {
      _latestResharePostMemory[uid] = null;
      return null;
    }

    final post = (await _postRepository.fetchPostCardsByIds(
      [postId],
      preferCache: true,
    ))[postId];
    _latestResharePostMemory[uid] = post;
    return post;
  }

  ProfileBuckets buildBucketsFromPosts(List<PostsModel> posts) {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final all = <PostsModel>[];
    final photos = <PostsModel>[];
    final videos = <PostsModel>[];
    final scheduled = <PostsModel>[];

    for (final post in posts) {
      final isIzBirakPost = post.scheduledAt.toInt() > 0;
      if (isIzBirakPost) {
        scheduled.add(post);
      }
      if (post.timeStamp > nowMs) {
        continue;
      }
      all.add(post);
      if (post.video.trim().isEmpty) {
        photos.add(post);
      }
      if (post.hasPlayableVideo) {
        videos.add(post);
      }
    }

    return ProfileBuckets(
      all: all,
      photos: photos,
      videos: videos,
      scheduled: scheduled,
    );
  }

  Future<void> clearUser(String uid) async {
    _memory.remove(uid);
    _archiveMemory.remove(uid);
    _latestPostMemory.remove(uid);
    _latestResharePostMemory.remove(uid);
    await _cacheService.clearUser(uid);
  }

  Future<void> removePostFromCaches({
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

  Future<List<PostsModel>> readCachedArchive(String uid) async {
    if (uid.isEmpty) return const <PostsModel>[];
    final fromMemory = _archiveMemory[uid];
    if (fromMemory != null) return List<PostsModel>.from(fromMemory);
    final archive = await _cacheService.readBucket(uid: uid, bucket: 'archive');
    if (archive.isEmpty) return const <PostsModel>[];
    _archiveMemory[uid] = List<PostsModel>.from(archive);
    return archive;
  }

  Future<void> writeArchive(String uid, List<PostsModel> posts) async {
    if (uid.isEmpty) return;
    _archiveMemory[uid] = List<PostsModel>.from(posts);
    await _cacheService.writeBucket(uid: uid, bucket: 'archive', posts: posts);
  }

  Future<List<PostsModel>> fetchArchive(String uid) async {
    if (uid.isEmpty) return const <PostsModel>[];
    final snapshot = await _firestore
        .collection('Posts')
        .where('userID', isEqualTo: uid)
        .where('arsiv', isEqualTo: true)
        .orderBy('timeStamp', descending: true)
        .get(const GetOptions(source: Source.serverAndCache));
    final postIds = snapshot.docs.map((doc) => doc.id).toList(growable: false);
    final byId = await _postRepository.fetchPostCardsByIds(
      postIds,
      preferCache: true,
    );
    final posts = postIds
        .map((id) => byId[id])
        .whereType<PostsModel>()
        .toList(growable: false);
    await writeArchive(uid, posts);
    return posts;
  }
}
