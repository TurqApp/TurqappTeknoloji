part of 'short_repository.dart';

extension ShortRepositoryQueryPart on ShortRepository {
  Future<ShortPageResult> _fetchReadyPageImpl({
    QueryDocumentSnapshot<Map<String, dynamic>>? startAfter,
    required int pageSize,
    int? nowMs,
  }) async {
    final ts = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final base = _firestore.collection('Posts');

    Query<Map<String, dynamic>> query = base
        .where('hlsStatus', isEqualTo: 'ready')
        .where('arsiv', isEqualTo: false)
        .where('deletedPost', isEqualTo: false)
        .where('timeStamp', isLessThanOrEqualTo: ts)
        .orderBy('timeStamp', descending: true)
        .limit(pageSize);
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    QuerySnapshot<Map<String, dynamic>> snap;
    try {
      snap = await PerformanceService.traceFeedLoad(
        () => query.get(),
        feedMode: 'short_page',
      );
    } catch (e) {
      final isIndexError = e is FirebaseException
          ? e.code == 'failed-precondition'
          : e.toString().contains('requires an index');
      if (!isIndexError) rethrow;

      Query<Map<String, dynamic>> fallback = base
          .where('arsiv', isEqualTo: false)
          .where('deletedPost', isEqualTo: false)
          .where('timeStamp', isLessThanOrEqualTo: ts)
          .orderBy('timeStamp', descending: true)
          .limit(pageSize);
      if (startAfter != null) {
        fallback = fallback.startAfterDocument(startAfter);
      }
      try {
        snap = await fallback.get();
      } catch (_) {
        Query<Map<String, dynamic>> broad = base
            .where('timeStamp', isLessThanOrEqualTo: ts)
            .orderBy('timeStamp', descending: true)
            .limit(pageSize);
        if (startAfter != null) {
          broad = broad.startAfterDocument(startAfter);
        }
        snap = await broad.get();
      }
    }

    if (snap.docs.isEmpty) {
      return ShortPageResult(const <PostsModel>[], startAfter, false);
    }

    return ShortPageResult(
      snap.docs
          .map((d) => PostsModel.fromMap(d.data(), d.id))
          .where((post) => post.timeStamp <= ts)
          .toList(growable: false),
      snap.docs.last,
      snap.docs.length == pageSize,
    );
  }
}
