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
    return _runPageQueryImpl(
      query,
      pageLimit: pageLimit,
      feedMode: 'explore_flood',
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
        .where('timeStamp', isLessThanOrEqualTo: ts)
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
