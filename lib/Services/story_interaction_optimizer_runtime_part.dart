part of 'story_interaction_optimizer.dart';

class _StoryInteractionOptimizerRuntimePart {
  final StoryInteractionOptimizer _service;

  const _StoryInteractionOptimizerRuntimePart(this._service);

  void handleOnInit() {
    _initializeLocalCache();
  }

  void handleOnClose() {
    _service._writeTimer?.cancel();
    _service._userSubscription?.cancel();
    _service._pendingOperations.clear();
    _service.localStoryCache.clear();
    _service.localTimeCache.clear();
  }

  void _initializeLocalCache() {
    _service._userSubscription =
        _service._userService.userStream.listen((user) {
      _service.localStoryCache.clear();
      _service.localTimeCache.clear();
      if (user == null) return;

      for (final userId in user.readStories) {
        _service.localStoryCache[userId] = true;
      }
      _service.localTimeCache.assignAll(user.readStoriesTimes);
    });
  }

  Future<void> markStoryViewed(
    String storyOwnerId,
    String storyId,
    int storyTime,
  ) async {
    try {
      _service.localStoryCache[storyOwnerId] = true;
      _service.localTimeCache[storyOwnerId] = storyTime;

      _service._pendingWrites[storyOwnerId] = storyTime;
      _service._pendingUsers.add(storyOwnerId);

      _service._writeTimer?.cancel();
      _service._writeTimer =
          Timer(const Duration(milliseconds: 500), _flushPendingWrites);
    } catch (e) {
      debugPrint('markStoryViewed error: $e');
      _service.localStoryCache[storyOwnerId] = true;
      _service.localTimeCache[storyOwnerId] = storyTime;
    }
  }

  Future<void> _flushPendingWrites() async {
    if (_service._pendingWrites.isEmpty || _service._isWriting) return;

    _service._isWriting = true;
    try {
      final uid = _service._userService.effectiveUserId;
      if (uid.isEmpty) {
        _service._isWriting = false;
        return;
      }

      final currentWrites = Map<String, int>.from(_service._pendingWrites);
      final currentUsers = Set<String>.from(_service._pendingUsers);

      _service._pendingWrites.clear();
      _service._pendingUsers.clear();

      final batch = FirebaseFirestore.instance.batch();
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(uid);

      for (final entry in currentWrites.entries) {
        batch.set(
          userDocRef.collection('readStories').doc(entry.key),
          {
            'storyId': entry.key,
            'readDate': entry.value,
            'updatedDate': DateTime.now().millisecondsSinceEpoch,
          },
          SetOptions(merge: true),
        );
      }

      if (currentUsers.isNotEmpty || currentWrites.isNotEmpty) {
        await batch.commit();
      }
    } catch (e) {
      debugPrint('Story batch write error: $e');

      try {
        final retryWrites = Map<String, int>.from(_service._pendingWrites);
        final retryUsers = Set<String>.from(_service._pendingUsers);

        for (final entry in retryWrites.entries) {
          _service._pendingWrites[entry.key] = entry.value;
        }
        _service._pendingUsers.addAll(retryUsers);

        Timer(const Duration(seconds: 2), _flushPendingWrites);
      } catch (retryError) {
        debugPrint('Story retry preparation error: $retryError');
      }
    } finally {
      _service._isWriting = false;
    }
  }

  bool areAllStoriesSeenCached(String storyOwnerId, List<dynamic> stories) {
    if (stories.isEmpty) return true;

    final isInReadList = _service.localStoryCache[storyOwnerId] ?? false;
    if (!isInReadList) return false;

    final lastSeenTime = _service.localTimeCache[storyOwnerId];
    if (lastSeenTime == null) return false;

    for (final story in stories) {
      final storyTime = story.createdAt?.millisecondsSinceEpoch ?? 0;
      if (storyTime > lastSeenTime) {
        return false;
      }
    }

    return true;
  }

  Future<void> forceFlush() async {
    _service._writeTimer?.cancel();

    if (_service._pendingOperations.isNotEmpty) {
      await Future.wait(_service._pendingOperations);
      _service._pendingOperations.clear();
    }

    await _flushPendingWrites();
  }

  Future<void> cleanup() async {
    _service._writeTimer?.cancel();
    await _service._userSubscription?.cancel();

    if (_service._pendingOperations.isNotEmpty) {
      try {
        await Future.wait(_service._pendingOperations, eagerError: false);
      } catch (e) {
        debugPrint('Story cleanup pending operation error: $e');
      }
      _service._pendingOperations.clear();
    }

    await _flushPendingWrites();
    _service.localStoryCache.clear();
    _service.localTimeCache.clear();
  }
}
