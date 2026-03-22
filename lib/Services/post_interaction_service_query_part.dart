part of 'post_interaction_service.dart';

extension PostInteractionServiceQueryPart on PostInteractionService {
  Future<Map<String, int>> getPostInteractionCounts(String postId) async {
    try {
      final snap = await _postRef(postId).get();
      final stats = _statsFromSnapshot(snap);
      return {
        'likes': stats.likeCount.toInt(),
        'comments': stats.commentCount.toInt(),
        'saves': stats.savedCount.toInt(),
        'reshares': stats.retryCount.toInt(),
        'views': stats.statsCount.toInt(),
        'reports': stats.reportedCount.toInt(),
      };
    } catch (e) {
      print('Get interaction counts error: $e');
      return const {
        'likes': 0,
        'comments': 0,
        'saves': 0,
        'reshares': 0,
        'views': 0,
        'reports': 0,
      };
    }
  }

  Future<Map<String, bool>> getUserInteractionStatus(String postId) async {
    final userId = currentUserID;
    if (userId == null) {
      return _emptyInteractionStatus;
    }

    final cacheKey = _cacheKey(userId, postId);
    final cached = _interactionStatusCache[cacheKey];
    if (cached != null && !cached.isExpired(PostInteractionService._cacheTTL)) {
      return Map<String, bool>.from(cached.status);
    }

    try {
      final futures = await Future.wait<UserSubcollectionEntry?>([
        _userSubcollectionRepository.getEntry(
          userId,
          subcollection: 'liked_posts',
          docId: postId,
          preferCache: true,
          forceRefresh: false,
        ),
        _userSubcollectionRepository.getEntry(
          userId,
          subcollection: 'saved_posts',
          docId: postId,
          preferCache: true,
          forceRefresh: false,
        ),
        _userSubcollectionRepository.getEntry(
          userId,
          subcollection: 'reshared_posts',
          docId: postId,
          preferCache: true,
          forceRefresh: false,
        ),
      ]);

      final status = <String, bool>{
        'liked': futures[0] != null,
        'saved': futures[1] != null,
        'reshared': futures[2] != null,
        'reported': _reportedByMe.contains(postId),
      };

      _interactionStatusCache[cacheKey] =
          _InteractionCacheEntry(status: status, fetchedAt: DateTime.now());
      return status;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        if (!_permissionDeniedLogged) {
          _permissionDeniedLogged = true;
          print(
              'Interaction status read denied by Firestore rules. Falling back to defaults.');
        }
        return _emptyInteractionStatus;
      }
      print('Get user interaction status error: $e');
      return _emptyInteractionStatus;
    } catch (e) {
      print('Get user interaction status error: $e');
      return _emptyInteractionStatus;
    }
  }

  Future<bool> isPostLiked(String postId) async {
    final userId = currentUserID;
    if (userId == null) return false;
    final entry = await _userSubcollectionRepository.getEntry(
      userId,
      subcollection: 'liked_posts',
      docId: postId,
      preferCache: true,
      forceRefresh: false,
    );
    return entry != null;
  }

  Future<bool> isPostSaved(String postId) async {
    final userId = currentUserID;
    if (userId == null) return false;
    final entry = await _userSubcollectionRepository.getEntry(
      userId,
      subcollection: 'saved_posts',
      docId: postId,
      preferCache: true,
      forceRefresh: false,
    );
    return entry != null;
  }

  Stream<List<PostCommentModel>> listenComments(String postId,
      {int limit = 50}) {
    return _postRef(postId)
        .collection('comments')
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PostCommentModel.fromFirestore(doc))
            .where((comment) => !comment.deleted)
            .toList());
  }

  Stream<List<SubCommentModel>> listenSubComments(
      String postId, String commentId,
      {int limit = 50}) {
    return _postRef(postId)
        .collection('comments')
        .doc(commentId)
        .collection('sub_comments')
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SubCommentModel.fromFirestore(doc))
            .where((comment) => !comment.deleted)
            .toList());
  }
}

const Map<String, bool> _emptyInteractionStatus = {
  'liked': false,
  'saved': false,
  'reshared': false,
  'reported': false,
};
