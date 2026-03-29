part of 'profile_repository_library.dart';

extension ProfileRepositoryQueryPart on ProfileRepository {
  String _asTrimmedString(dynamic value) => (value ?? '').toString().trim();

  Map<String, dynamic> _coerceMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Map<String, dynamic>.from(value);
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  PostsModel? _mergeSnapshotCard({
    required String postId,
    required PostsModel? card,
    required Map<String, dynamic>? snapshotData,
  }) {
    final base = card ??
        (snapshotData == null
            ? null
            : PostsModel.fromMap(snapshotData, postId));
    if (base == null || snapshotData == null) return base;

    final poll = _coerceMap(snapshotData['poll']);
    if (poll.isEmpty) return base;

    _postRepository.mergeCachedPostData(postId, {'poll': poll});
    if (base.poll.length == poll.length &&
        base.poll.entries.every((entry) => poll[entry.key] == entry.value)) {
      return base;
    }
    return base.copyWith(poll: poll);
  }

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
    final snapshotDataById = <String, Map<String, dynamic>>{
      for (final doc in snapshot.docs) doc.id: doc.data(),
    };
    final byId = await _postRepository.fetchPostCardsByIds(
      postIds,
      preferCache: true,
    );
    final buckets = buildBucketsFromPosts(
      postIds
          .map(
            (id) => _mergeSnapshotCard(
              postId: id,
              card: byId[id],
              snapshotData: snapshotDataById[id],
            ),
          )
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

    final doc = snapshot.docs.first;
    final post = _mergeSnapshotCard(
      postId: doc.id,
      card: (await _postRepository.fetchPostCardsByIds(
        [doc.id],
        preferCache: true,
      ))[doc.id],
      snapshotData: doc.data(),
    );
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

    final postId = _asTrimmedString(snapshot.docs.first.data()['post_docID']);
    if (postId.isEmpty) {
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
    final snapshotDataById = <String, Map<String, dynamic>>{
      for (final doc in snapshot.docs) doc.id: doc.data(),
    };
    final byId = await _postRepository.fetchPostCardsByIds(
      postIds,
      preferCache: true,
    );
    final posts = postIds
        .map(
          (id) => _mergeSnapshotCard(
            postId: id,
            card: byId[id],
            snapshotData: snapshotDataById[id],
          ),
        )
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
