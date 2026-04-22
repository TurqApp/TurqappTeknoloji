part of 'explore_repository.dart';

extension ExploreRepositoryQueryPart on ExploreRepository {
  Future<ExploreQueryPage> _fetchExplorePostsPageImpl({
    DocumentSnapshot? startAfter,
    required int pageLimit,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('timeStamp', descending: true)
        .limit(pageLimit * 3);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQueryImpl(
      query,
      excludeSeriesRoots: true,
      pageLimit: pageLimit,
      feedMode: 'explore_posts',
    );
  }

  Future<ExploreQueryPage> _fetchVideoReadyPageImpl({
    DocumentSnapshot? startAfter,
    required int pageLimit,
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
        .limit(pageLimit * 3);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQueryImpl(
      query,
      excludeSeriesRoots: true,
      pageLimit: pageLimit,
      feedMode: 'explore_video',
    );
  }

  Future<ExploreQueryPage> _fetchVideoFallbackPageImpl({
    DocumentSnapshot? startAfter,
    required int pageLimit,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('timeStamp', descending: true)
        .limit(pageLimit * 3);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQueryImpl(
      query,
      excludeSeriesRoots: true,
      pageLimit: pageLimit,
      feedMode: 'explore_video_fallback',
    );
  }

  Future<ExploreQueryPage> _fetchVideoBroadPageImpl({
    DocumentSnapshot? startAfter,
    required int pageLimit,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('timeStamp', descending: true)
        .limit(pageLimit * 3);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQueryImpl(
      query,
      excludeSeriesRoots: true,
      pageLimit: pageLimit,
      feedMode: 'explore_video_broad',
    );
  }

  Future<ExploreQueryPage> _fetchPhotoPageImpl({
    DocumentSnapshot? startAfter,
    required int pageLimit,
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
        .limit(pageLimit * 3);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQueryImpl(
      query,
      excludeSeriesRoots: true,
      pageLimit: pageLimit,
      feedMode: 'explore_photo',
    );
  }

  Future<ExploreQueryPage> _fetchFloodServerPageImpl({
    DocumentSnapshot? startAfter,
    required int pageLimit,
    int? nowMs,
  }) async {
    final manifestPage = await _fetchFloodManifestPageImpl(
      startAfter: startAfter,
      pageLimit: pageLimit,
      nowMs: nowMs,
    );
    if (manifestPage.items.isNotEmpty || manifestPage.hasMore) {
      return manifestPage;
    }
    return _fetchFloodFallbackPageImpl(
      startAfter: startAfter,
      pageLimit: pageLimit,
      nowMs: nowMs,
    );
  }

  Future<ExploreQueryPage> _fetchFloodManifestPageImpl({
    DocumentSnapshot? startAfter,
    required int pageLimit,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('floodManifest')
        .orderBy('updatedAtMs', descending: true)
        .limit(pageLimit * 2);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    final snap = await PerformanceService.traceFeedLoad(
      () => query.get(),
      feedMode: 'explore_flood_manifest',
    );
    final items = snap.docs
        .map((doc) {
          final data = doc.data();
          final kind = (data['kind'] ?? '').toString().trim();
          final eligible = data['eligible'] == true;
          if (kind != 'flood' || !eligible) {
            return null;
          }
          final mainPostId =
              (data['mainPostId'] ?? data['floodRootId'] ?? doc.id)
                  .toString()
                  .trim();
          if (mainPostId.isEmpty) return null;
          try {
            return PostsModel.fromMap(data, mainPostId);
          } catch (_) {
            return null;
          }
        })
        .whereType<PostsModel>()
        .where((item) => !item.shouldHideWhileUploading)
        .where((item) => item.floodCount > 1)
        .where((item) => item.timeStamp <= ts)
        .take(pageLimit)
        .toList(growable: false);
    return ExploreQueryPage(
      items,
      snap.docs.isEmpty ? null : snap.docs.last,
      snap.docs.length >= pageLimit,
    );
  }

  Future<ExploreQueryPage> _fetchFloodFallbackPageImpl({
    DocumentSnapshot? startAfter,
    required int pageLimit,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    Query<Map<String, dynamic>> query = _firestore
        .collection('Posts')
        .where('arsiv', isEqualTo: false)
        .where('flood', isEqualTo: false)
        .where('floodCount', isGreaterThan: 1)
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('floodCount')
        .orderBy('timeStamp', descending: true)
        .limit(pageLimit);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    return _runPageQueryImpl(
      query,
      pageLimit: pageLimit,
      feedMode: 'explore_flood_fallback',
    );
  }

}
