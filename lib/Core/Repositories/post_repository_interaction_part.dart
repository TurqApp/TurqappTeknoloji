part of 'post_repository.dart';

extension PostRepositoryInteractionPart on PostRepository {
  PostRepositoryState _performAttachPost(
    PostsModel model, {
    required bool loadInteraction,
    required bool loadCommentMembership,
  }) {
    final state = _states.putIfAbsent(
        model.docID, () => PostRepositoryState(model.docID));
    state.retainCount++;
    _seedCounts(state, model);
    _startPostStream(state);
    if (loadInteraction) {
      unawaited(_ensureInteraction(state));
    }
    if (loadCommentMembership) {
      _startCommentsMembershipStream(state);
    }
    return state;
  }

  void _performReleasePost(String postId) {
    final state = _states[postId];
    if (state == null) return;
    state.retainCount--;
    if (state.retainCount > 0) return;
    state.postSub?.cancel();
    state.postSub = null;
    state.commentsSub?.cancel();
    state.commentsSub = null;
  }

  Future<bool> _performToggleLike(PostsModel model) async {
    final state = attachPost(model);
    final wasLiked = state.liked.value;
    final target = !wasLiked;
    state.liked.value = target;
    _applyCountDelta(
      postId: model.docID,
      from: wasLiked,
      to: target,
      countRx: _countManager.getLikeCount(model.docID),
      readStat: () => model.stats.likeCount,
      writeStat: (value) => model.stats.likeCount = value,
    );

    try {
      final actual = await _interactionService.toggleLike(model.docID);
      if (actual != target) {
        state.liked.value = actual;
        _applyCountDelta(
          postId: model.docID,
          from: target,
          to: actual,
          countRx: _countManager.getLikeCount(model.docID),
          readStat: () => model.stats.likeCount,
          writeStat: (value) => model.stats.likeCount = value,
        );
      }
      return actual;
    } catch (_) {
      state.liked.value = wasLiked;
      _applyCountDelta(
        postId: model.docID,
        from: target,
        to: wasLiked,
        countRx: _countManager.getLikeCount(model.docID),
        readStat: () => model.stats.likeCount,
        writeStat: (value) => model.stats.likeCount = value,
      );
      rethrow;
    }
  }

  Future<bool> _performToggleSave(PostsModel model) async {
    final state = attachPost(model);
    final wasSaved = state.saved.value;
    final target = !wasSaved;
    state.saved.value = target;
    _applyCountDelta(
      postId: model.docID,
      from: wasSaved,
      to: target,
      countRx: _countManager.getSavedCount(model.docID),
      readStat: () => model.stats.savedCount,
      writeStat: (value) => model.stats.savedCount = value,
    );

    try {
      final actual = await _interactionService.toggleSave(model.docID);
      if (actual != target) {
        state.saved.value = actual;
        _applyCountDelta(
          postId: model.docID,
          from: target,
          to: actual,
          countRx: _countManager.getSavedCount(model.docID),
          readStat: () => model.stats.savedCount,
          writeStat: (value) => model.stats.savedCount = value,
        );
      }
      return actual;
    } catch (_) {
      state.saved.value = wasSaved;
      _applyCountDelta(
        postId: model.docID,
        from: target,
        to: wasSaved,
        countRx: _countManager.getSavedCount(model.docID),
        readStat: () => model.stats.savedCount,
        writeStat: (value) => model.stats.savedCount = value,
      );
      rethrow;
    }
  }

  Future<bool> _performToggleReshare(PostsModel model) async {
    final state = attachPost(model);
    final wasReshared = state.reshared.value;
    final target = !wasReshared;
    state.reshared.value = target;
    _applyCountDelta(
      postId: model.docID,
      from: wasReshared,
      to: target,
      countRx: _countManager.getRetryCount(model.docID),
      readStat: () => model.stats.retryCount,
      writeStat: (value) => model.stats.retryCount = value,
    );

    try {
      final actual = await _interactionService.toggleReshare(model.docID);
      if (actual != target) {
        state.reshared.value = actual;
        _applyCountDelta(
          postId: model.docID,
          from: target,
          to: actual,
          countRx: _countManager.getRetryCount(model.docID),
          readStat: () => model.stats.retryCount,
          writeStat: (value) => model.stats.retryCount = value,
        );
      }
      return actual;
    } catch (_) {
      state.reshared.value = wasReshared;
      _applyCountDelta(
        postId: model.docID,
        from: target,
        to: wasReshared,
        countRx: _countManager.getRetryCount(model.docID),
        readStat: () => model.stats.retryCount,
        writeStat: (value) => model.stats.retryCount = value,
      );
      rethrow;
    }
  }

  Future<void> _performRefreshInteraction(String postId) async {
    final state = _states[postId];
    if (state == null) return;
    state.interactionFetchedAt = null;
    await _ensureInteraction(state, forceRefresh: true);
  }

  Future<void> _performSetArchived(PostsModel model, bool archived) async {
    await _firestore.collection('Posts').doc(model.docID).update({
      'arsiv': archived,
    });

    final me = _auth.currentUser?.uid;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final isVisible = (model.timeStamp <= nowMs) && !model.flood;
    if (me != null && model.userID == me && isVisible) {
      await UserRepository.ensure().updateUserFields(
        me,
        {
          'counterOfPosts': FieldValue.increment(archived ? -1 : 1),
        },
        mergeIntoCache: false,
      );
    }

    final state = _states[model.docID];
    final latest = state?.latestPostData.value;
    if (latest != null) {
      state!.latestPostData.value = {
        ...latest,
        'arsiv': archived,
      };
    }
  }

  void _performSeedCounts(PostRepositoryState state, PostsModel model) {
    if (state.latestPostData.value != null) return;
    _countManager.initializeCounts(
      model.docID,
      likeCount: model.stats.likeCount.toInt(),
      commentCount: model.stats.commentCount.toInt(),
      savedCount: model.stats.savedCount.toInt(),
      retryCount: model.stats.retryCount.toInt(),
      statsCount: model.stats.statsCount.toInt(),
    );
  }

  void _performStartPostStream(PostRepositoryState state) {
    if (state.postSub != null) return;
    state.postSub = _firestore
        .collection('Posts')
        .doc(state.postId)
        .snapshots()
        .listen((doc) {
      final data = doc.data();
      if (data == null) return;
      final stats =
          data['stats'] as Map<String, dynamic>? ?? const <String, dynamic>{};
      _countManager.getLikeCount(state.postId).value =
          ((stats['likeCount'] ?? data['likeCount'] ?? 0) as num).toInt();
      _countManager.getCommentCount(state.postId).value =
          ((stats['commentCount'] ?? data['commentCount'] ?? 0) as num).toInt();
      _countManager.getSavedCount(state.postId).value =
          ((stats['savedCount'] ?? data['savedCount'] ?? 0) as num).toInt();
      _countManager.getRetryCount(state.postId).value =
          ((stats['retryCount'] ?? data['retryCount'] ?? 0) as num).toInt();
      _countManager.getStatsCount(state.postId).value =
          ((stats['statsCount'] ?? data['statsCount'] ?? 0) as num).toInt();
      state.latestPostData.value = Map<String, dynamic>.from(data);
    }, onError: (error) {
      debugPrint('PostRepository post stream error (${state.postId}): $error');
    });
  }

  void _performStartCommentsMembershipStream(PostRepositoryState state) {
    if (state.commentsSub != null) return;
    final userId = _auth.currentUser?.uid;
    if (userId == null || userId.trim().isEmpty) {
      state.commented.value = false;
      return;
    }
    state.commentsSub = _firestore
        .collection('Posts')
        .doc(state.postId)
        .collection('comments')
        .where('deleted', isEqualTo: false)
        .where('userID', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .listen((snap) {
      state.commented.value = snap.docs.isNotEmpty;
    }, onError: (error) {
      state.commented.value = false;
      debugPrint(
        'PostRepository comments membership stream error (${state.postId}): $error',
      );
    });
  }

  Future<void> _performEnsureInteraction(
    PostRepositoryState state, {
    required bool forceRefresh,
  }) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      state.liked.value = false;
      state.saved.value = false;
      state.reshared.value = false;
      state.reported.value = false;
      return;
    }
    if (state.interactionLoading) return;
    if (!forceRefresh &&
        state.interactionFetchedAt != null &&
        DateTime.now().difference(state.interactionFetchedAt!) <
            PostRepository._interactionTtl) {
      return;
    }
    state.interactionLoading = true;
    try {
      final status =
          await _interactionService.getUserInteractionStatus(state.postId);
      state.liked.value = status['liked'] ?? false;
      state.saved.value = status['saved'] ?? false;
      state.reshared.value = status['reshared'] ?? false;
      state.reported.value = status['reported'] ?? false;
      state.interactionFetchedAt = DateTime.now();
    } finally {
      state.interactionLoading = false;
    }
  }

  void _performApplyCountDelta({
    required String postId,
    required bool from,
    required bool to,
    required RxInt countRx,
    required num Function() readStat,
    required void Function(num value) writeStat,
  }) {
    final delta = (to ? 1 : 0) - (from ? 1 : 0);
    if (delta == 0) return;
    final nextCount = countRx.value + delta;
    countRx.value = nextCount < 0 ? 0 : nextCount;
    final statNext = readStat() + delta;
    writeStat(statNext < 0 ? 0 : statNext);
  }
}
