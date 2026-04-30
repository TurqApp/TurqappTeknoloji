part of 'story_repository.dart';

extension StoryRepositoryEngagementPart on StoryRepository {
  Future<List<String>> _performFetchStoryViewerIds(
    String storyId, {
    required int limit,
  }) async {
    if (storyId.isEmpty) return const <String>[];
    final snap = await AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Viewers')
        .limit(limit)
        .get();
    return snap.docs.map((doc) => doc.id).toList(growable: false);
  }

  Future<int> _performFetchStoryViewerCount(String storyId) async {
    if (storyId.isEmpty) return 0;
    final counts = await AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Viewers')
        .count()
        .get();
    return counts.count ?? 0;
  }

  Future<List<StoryCommentModel>> _performFetchStoryComments(
    String storyId, {
    required int limit,
  }) async {
    if (storyId.isEmpty) return const <StoryCommentModel>[];
    final snap = await AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Yorumlar')
        .orderBy('timeStamp', descending: true)
        .limit(limit)
        .get();
    return snap.docs
        .map((doc) => StoryCommentModel.fromMap(doc.data(), docID: doc.id))
        .toList(growable: false);
  }

  Future<int> _performFetchStoryCommentCount(String storyId) async {
    if (storyId.isEmpty) return 0;
    final counts = await AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Yorumlar')
        .count()
        .get();
    return counts.count ?? 0;
  }

  Future<StoryCommentModel?> _performFetchLatestStoryComment(
    String storyId,
  ) async {
    if (storyId.isEmpty) return null;
    final snap = await AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Yorumlar')
        .limit(1)
        .orderBy('timeStamp', descending: true)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    return StoryCommentModel.fromMap(doc.data(), docID: doc.id);
  }

  Future<void> _performAddStoryComment(
    String storyId, {
    required String userId,
    required String text,
    required String gif,
  }) async {
    if (storyId.isEmpty || userId.isEmpty) return;
    await AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Yorumlar')
        .add({
      'userID': userId,
      'metin': text,
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
      'gif': gif,
    });
  }

  Future<void> _performDeleteStoryComment(
    String storyId, {
    required String commentId,
  }) async {
    if (storyId.isEmpty || commentId.isEmpty) return;
    await AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Yorumlar')
        .doc(commentId)
        .delete();
  }

  Future<void> _performAddScreenshotEvent(
    String storyId, {
    required String userId,
  }) async {
    if (storyId.isEmpty || userId.isEmpty) return;
    await AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('screenshots')
        .doc(userId)
        .set({
      'userId': userId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> _performMarkUserStoriesFullyViewed({
    required String currentUid,
    required String targetUserId,
    required int latestStoryTime,
  }) async {
    if (currentUid.isEmpty || targetUserId.isEmpty || latestStoryTime <= 0) {
      return;
    }
    await AppFirestore.instance
        .collection('users')
        .doc(currentUid)
        .collection('readStories')
        .doc(targetUserId)
        .set({
      'storyId': targetUserId,
      'readDate': latestStoryTime,
      'lastSeenAt': latestStoryTime,
      'updatedDate': DateTime.now().millisecondsSinceEpoch,
    }, SetOptions(merge: true));
  }

  Future<List<String>> _performFetchStoryLikeIds(String storyId) async {
    if (storyId.isEmpty) return const <String>[];
    final snap = await AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('likes')
        .get();
    return snap.docs.map((doc) => doc.id).toList(growable: false);
  }

  Future<int> _performFetchStoryLikeCount(String storyId) async {
    if (storyId.isEmpty) return 0;
    final counts = await AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('likes')
        .count()
        .get();
    return counts.count ?? 0;
  }

  Future<StoryEngagementSnapshot> _performFetchStoryEngagement(
    String storyId, {
    required String currentUid,
  }) async {
    if (storyId.isEmpty) {
      return StoryEngagementSnapshot(
        likeCount: 0,
        isLiked: false,
        reactionCounts: <String, int>{},
        myReaction: '',
      );
    }

    final likeCountFuture = fetchStoryLikeCount(storyId);
    final likeStatusFuture = currentUid.trim().isEmpty
        ? Future<bool>.value(false)
        : AppFirestore.instance
            .collection('stories')
            .doc(storyId)
            .collection('likes')
            .doc(currentUid)
            .get()
            .then((doc) => doc.exists)
            .catchError((_) => false);
    final storyRawFuture = getStoryRaw(storyId, preferCache: true);

    final results = await Future.wait<dynamic>([
      likeCountFuture,
      likeStatusFuture,
      storyRawFuture,
    ]);

    final likeCount = results[0] as int? ?? 0;
    final isLiked = results[1] as bool? ?? false;
    final data = results[2] as Map<String, dynamic>?;

    final reactionCounts = <String, int>{};
    var myReaction = '';
    if (data != null && data['reactions'] is Map) {
      final reactions = Map<String, dynamic>.from(data['reactions']);
      for (final entry in reactions.entries) {
        final users = List<String>.from(entry.value ?? const <String>[]);
        reactionCounts[entry.key] = users.length;
        if (currentUid.isNotEmpty && users.contains(currentUid)) {
          myReaction = entry.key;
        }
      }
    }

    return StoryEngagementSnapshot(
      likeCount: likeCount,
      isLiked: isLiked,
      reactionCounts: reactionCounts,
      myReaction: myReaction,
    );
  }

  Future<bool> _performToggleStoryLike(
    String storyId, {
    required String currentUid,
  }) async {
    if (storyId.isEmpty || currentUid.trim().isEmpty) return false;
    final docRef = AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('likes')
        .doc(currentUid);

    final doc = await docRef.get();
    if (doc.exists) {
      await docRef.delete();
      return false;
    }
    await docRef.set({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
    });
    return true;
  }

  Future<String> _performToggleStoryReaction(
    String storyId, {
    required String currentUid,
    required String emoji,
    required String currentReaction,
  }) async {
    if (storyId.isEmpty || currentUid.trim().isEmpty || emoji.trim().isEmpty) {
      return currentReaction;
    }
    final docRef = AppFirestore.instance.collection('stories').doc(storyId);

    if (currentReaction == emoji) {
      await docRef.update({
        'reactions.$emoji': FieldValue.arrayRemove([currentUid]),
      });
      return '';
    }

    if (currentReaction.isNotEmpty) {
      await docRef.update({
        'reactions.$currentReaction': FieldValue.arrayRemove([currentUid]),
      });
    }
    await docRef.update({
      'reactions.$emoji': FieldValue.arrayUnion([currentUid]),
    });
    return emoji;
  }

  Future<void> _performSetStorySeen(
    String storyId, {
    required String currentUid,
  }) async {
    if (storyId.isEmpty || currentUid.trim().isEmpty) return;
    await AppFirestore.instance
        .collection('stories')
        .doc(storyId)
        .collection('Viewers')
        .doc(currentUid)
        .set({
      'timeStamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
