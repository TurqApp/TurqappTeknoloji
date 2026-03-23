part of 'profile_repository.dart';

extension ProfileRepositoryQueryPart on ProfileRepository {
  Future<ProfilePageResult> _fetchPrimaryPageImpl({
    required String uid,
    required DocumentSnapshot<Map<String, dynamic>>? startAfter,
    required int limit,
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

  Future<PostsModel?> _fetchLatestProfilePostImpl(String uid) async {
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

  Future<PostsModel?> _fetchLatestResharePostImpl(String uid) async {
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

  Future<List<PostsModel>> _fetchArchiveImpl(String uid) async {
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

  ProfileBuckets _buildBucketsFromPostsImpl(List<PostsModel> posts) {
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
}
