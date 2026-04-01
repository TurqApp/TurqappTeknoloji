part of 'social_profile_controller.dart';

extension SocialProfileControllerFeedSelectionPart on SocialProfileController {
  void _performBootstrapFeedPlaybackAfterDataChange() {
    if (postSelection.value != 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (postSelection.value != 0) return;
      final activeEntries = combinedFeedEntries;
      if (activeEntries.isEmpty) {
        centeredIndex.value = -1;
        currentVisibleIndex.value = -1;
        lastCenteredIndex = null;
        return;
      }
      final target = resolveResumeCenteredIndex();
      if (target < 0 || target >= activeEntries.length) return;
      centeredIndex.value = target;
      currentVisibleIndex.value = target;
      lastCenteredIndex = target;
      capturePendingCenteredEntry(preferredIndex: target);
      if (_performCanAutoplayCombinedEntry(activeEntries[target])) {
        _performEnsureCenteredPlaybackForIndex(target);
      } else {
        _performScheduleVisibilityEvaluation();
      }
    });
  }

  int _performResolveResumeCenteredIndex() {
    final activeLength =
        postSelection.value == 0 ? combinedFeedEntries.length : allPosts.length;
    if (activeLength == 0) return -1;
    final pendingIdentity = _pendingCenteredIdentity;
    if (pendingIdentity != null && pendingIdentity.isNotEmpty) {
      final pendingIndex = postSelection.value == 0
          ? combinedFeedEntries.indexWhere((entry) {
              final entryDocId = ((entry['docID'] as String?) ?? '').trim();
              final entryIsReshare = entry['isReshare'] == true;
              return combinedEntryIdentity(
                    docId: entryDocId,
                    isReshare: entryIsReshare,
                  ) ==
                  pendingIdentity;
            })
          : allPosts
              .indexWhere((post) => 'post_${post.docID}' == pendingIdentity);
      if (pendingIndex >= 0) {
        return pendingIndex;
      }
    }
    if (lastCenteredIndex != null &&
        lastCenteredIndex! >= 0 &&
        lastCenteredIndex! < activeLength) {
      return lastCenteredIndex!;
    }
    if (centeredIndex.value >= 0 && centeredIndex.value < activeLength) {
      return centeredIndex.value;
    }
    return 0;
  }

  void _performResumeCenteredPost() {
    final activeCombinedEntries = postSelection.value == 0
        ? combinedFeedEntries
        : const <Map<String, dynamic>>[];
    final activeLength = postSelection.value == 0
        ? activeCombinedEntries.length
        : allPosts.length;
    final expectedDocId = (lastCenteredIndex != null &&
            lastCenteredIndex! >= 0 &&
            lastCenteredIndex! < activeLength)
        ? postSelection.value == 0
            ? ((activeCombinedEntries[lastCenteredIndex!]['docID']
                    as String?) ??
                '')
            : allPosts[lastCenteredIndex!].docID
        : null;
    final target = resolveResumeCenteredIndex();
    if (target < 0 || target >= activeLength) return;
    lastCenteredIndex = target;
    centeredIndex.value = target;
    currentVisibleIndex.value = target;
    capturePendingCenteredEntry(preferredIndex: target);
    _invariantGuard.assertCenteredSelection(
      surface: 'social_profile',
      invariantKey: 'resume_centered_post',
      centeredIndex: centeredIndex.value,
      docIds: postSelection.value == 0
          ? activeCombinedEntries
              .map((entry) => ((entry['docID'] as String?) ?? ''))
              .toList(growable: false)
          : allPosts.map((post) => post.docID).toList(growable: false),
      expectedDocId: expectedDocId,
      payload: <String, dynamic>{
        'target': target,
      },
    );
    if (postSelection.value == 0) {
      _performEnsureCenteredPlaybackForIndex(target);
    }
  }

  void _performCapturePendingCenteredEntry({
    int? preferredIndex,
    PostsModel? model,
    bool isReshare = false,
  }) {
    if (model != null) {
      final docId = model.docID.trim();
      if (docId.isEmpty) {
        _pendingCenteredIdentity = null;
        return;
      }
      _pendingCenteredIdentity = postSelection.value == 0
          ? combinedEntryIdentity(docId: docId, isReshare: isReshare)
          : 'post_$docId';
      return;
    }

    final activeLength =
        postSelection.value == 0 ? combinedFeedEntries.length : allPosts.length;
    final candidateIndex = preferredIndex ??
        (currentVisibleIndex.value >= 0
            ? currentVisibleIndex.value
            : lastCenteredIndex);
    if (candidateIndex == null ||
        candidateIndex < 0 ||
        candidateIndex >= activeLength) {
      _pendingCenteredIdentity = null;
      return;
    }

    if (postSelection.value == 0) {
      final entry = combinedFeedEntries[candidateIndex];
      final docId = ((entry['docID'] as String?) ?? '').trim();
      if (docId.isEmpty) {
        _pendingCenteredIdentity = null;
        return;
      }
      _pendingCenteredIdentity = combinedEntryIdentity(
        docId: docId,
        isReshare: entry['isReshare'] == true,
      );
      return;
    }

    final docId = allPosts[candidateIndex].docID.trim();
    _pendingCenteredIdentity = docId.isEmpty ? null : 'post_$docId';
  }

  String _performCombinedEntryIdentity({
    required String docId,
    required bool isReshare,
  }) {
    return '${isReshare ? 'reshare' : 'post'}_$docId';
  }

  bool _performCanAutoplayCombinedEntry(Map<String, dynamic> entry) {
    final post = entry['post'];
    if (post is! PostsModel) return false;
    if (post.deletedPost) return false;
    if (post.arsiv) return false;
    return post.hasPlayableVideo;
  }

  void _performOnPostVisibilityChanged(int modelIndex, double visibleFraction) {
    if (postSelection.value != 0) return;
    if (showPfImage.value) return;
    final activeEntries = combinedFeedEntries;
    if (modelIndex < 0 || modelIndex >= activeEntries.length) return;
    if (!_performCanAutoplayCombinedEntry(activeEntries[modelIndex])) return;

    final prev = _visibleFractions[modelIndex];
    if (FeedPlaybackSelectionPolicy.shouldIgnoreVisibilityUpdate(
      previousFraction: prev,
      visibleFraction: visibleFraction,
    )) {
      return;
    }

    if (visibleFraction <= 0.01) {
      _visibleFractions.remove(modelIndex);
    } else {
      _visibleFractions[modelIndex] = visibleFraction;
    }

    _performScheduleVisibilityEvaluation();
  }

  bool _performShouldPinTopFeedTarget() {
    if (postSelection.value != 0) return false;
    if (!scrollController.hasClients) return false;
    if (scrollController.offset > 24) return false;
    final activeEntries = combinedFeedEntries;
    if (activeEntries.isEmpty) return false;
    return _performCanAutoplayCombinedEntry(activeEntries.first);
  }

  void _performScheduleVisibilityEvaluation() {
    _visibilityDebounce?.cancel();
    _visibilityDebounce = Timer(
      FeedPlaybackSelectionPolicy.evaluationDebounceDuration,
      _performEvaluateCenteredPlayback,
    );
  }

  void _performEvaluateCenteredPlayback() {
    if (postSelection.value != 0) return;
    final activeEntries = combinedFeedEntries;
    if (activeEntries.isEmpty) return;
    final current = centeredIndex.value;
    if (current >= 0 && current < activeEntries.length) {
      final currentEntry = activeEntries[current];
      final currentDocId = ((currentEntry['docID'] as String?) ?? '').trim();
      if (currentDocId.isNotEmpty) {
        final currentPlaybackKey = _performAgendaInstanceTag(
          docId: currentDocId,
          isReshare: currentEntry['isReshare'] == true,
        );
        final currentFraction = _visibleFractions[current] ?? 0.0;
        if (FeedPlaybackSelectionPolicy.shouldRetainRecentlyActivatedTarget(
          lastCommandAt: _lastPlaybackCommandAt,
          lastCommandDocId: _lastPlaybackCommandDocId,
          currentDocId: currentPlaybackKey,
          isCurrentTargetActive: _performIsPlaybackTargetCurrent(current),
          currentFraction: currentFraction,
          stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
        )) {
          lastCenteredIndex = current;
          currentVisibleIndex.value = current;
          return;
        }
      }
    }

    final targetIndex = _performShouldPinTopFeedTarget()
        ? 0
        : FeedPlaybackSelectionPolicy.resolveCenteredIndex(
            visibleFractions: _visibleFractions,
            currentIndex: centeredIndex.value,
            lastCenteredIndex: lastCenteredIndex,
            itemCount: activeEntries.length,
            canAutoplayIndex: (index) =>
                _performCanAutoplayCombinedEntry(activeEntries[index]),
            stopThreshold: FeedPlaybackSelectionPolicy.stopThreshold,
          );

    if (targetIndex >= 0 && targetIndex < activeEntries.length) {
      final centeredChanged = centeredIndex.value != targetIndex;
      if (centeredChanged) {
        centeredIndex.value = targetIndex;
      }
      currentVisibleIndex.value = targetIndex;
      lastCenteredIndex = targetIndex;
      // Social profile feed has no separate centered-index playback listener,
      // so target changes must dispatch playback immediately here.
      if (centeredChanged || !_performIsPlaybackTargetCurrent(targetIndex)) {
        _performEnsureCenteredPlaybackForIndex(targetIndex);
      }
    } else {
      centeredIndex.value = -1;
    }
  }

  List<Map<String, dynamic>> _performCombinedFeedEntries() {
    final combinedPosts = <Map<String, dynamic>>[];

    for (final post in allPosts) {
      combinedPosts.add(<String, dynamic>{
        'docID': post.docID,
        'post': post,
        'isReshare': false,
        'timestamp': post.timeStamp,
      });
    }

    for (final reshare in reshares) {
      combinedPosts.add(<String, dynamic>{
        'docID': reshare.docID,
        'post': reshare,
        'isReshare': true,
        'timestamp': reshare.timeStamp,
      });
    }

    combinedPosts.sort(
      (a, b) => (b['timestamp'] as num).compareTo(a['timestamp'] as num),
    );
    return combinedPosts;
  }

  int _performIndexOfCombinedEntry({
    required String docId,
    required bool isReshare,
  }) {
    final identity = combinedEntryIdentity(
      docId: docId,
      isReshare: isReshare,
    );
    return combinedFeedEntries.indexWhere((entry) {
      final entryDocId = ((entry['docID'] as String?) ?? '').trim();
      final entryIsReshare = entry['isReshare'] == true;
      return combinedEntryIdentity(
            docId: entryDocId,
            isReshare: entryIsReshare,
          ) ==
          identity;
    });
  }

  String _performAgendaInstanceTag({
    required String docId,
    required bool isReshare,
  }) {
    return 'social_${isReshare ? 'reshare' : 'post'}_$docId';
  }

  Future<void> _performDisposeAgendaContentController(String docID) async {
    final tags = <String>{
      agendaInstanceTag(docId: docID, isReshare: false),
      agendaInstanceTag(docId: docID, isReshare: true),
    };
    for (final tag in tags) {
      if (AgendaContentController.maybeFind(tag: tag) != null) {
        Get.delete<AgendaContentController>(tag: tag, force: true);
      }
    }
  }

  bool _performIsPlaybackTargetCurrent(int index) {
    final activeEntries = combinedFeedEntries;
    if (index < 0 || index >= activeEntries.length) return false;
    final entry = activeEntries[index];
    final docId = ((entry['docID'] as String?) ?? '').trim();
    if (docId.isEmpty) return false;
    final playbackKey = agendaInstanceTag(
      docId: docId,
      isReshare: entry['isReshare'] == true,
    );
    return VideoStateManager.instance.isPlaybackTargetActive(playbackKey);
  }

  void _performEnsureCenteredPlaybackForIndex(int index) {
    if (postSelection.value != 0) return;
    if (showPfImage.value) return;
    final activeEntries = combinedFeedEntries;
    if (index < 0 || index >= activeEntries.length) return;
    final entry = activeEntries[index];
    if (!_performCanAutoplayCombinedEntry(entry)) return;
    final docId = ((entry['docID'] as String?) ?? '').trim();
    if (docId.isEmpty) return;
    final playbackKey = agendaInstanceTag(
      docId: docId,
      isReshare: entry['isReshare'] == true,
    );
    final manager = VideoStateManager.instance;
    final issuedAt = manager.activatePlaybackTargetIfReady(
      playbackKey,
      lastCommandDocId: _lastPlaybackCommandDocId,
      lastCommandAt: _lastPlaybackCommandAt,
    );
    if (issuedAt == null) return;
    _lastPlaybackCommandDocId = playbackKey;
    _lastPlaybackCommandAt = issuedAt;
  }
}
