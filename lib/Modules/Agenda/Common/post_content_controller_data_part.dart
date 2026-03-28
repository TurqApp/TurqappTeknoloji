part of 'post_content_controller.dart';

extension PostContentControllerDataPart on PostContentController {
  int _pollExpiresAtMs(Map<String, dynamic> poll) {
    final createdAt = (poll['createdDate'] ?? model.timeStamp) as num;
    final durationHours = (poll['durationHours'] ?? 24) as num;
    return createdAt.toInt() + (durationHours.toInt() * 3600 * 1000);
  }

  int? get _cachedPollSelection =>
      _postState?.localPollSelection.value ?? _localPollSelection.value;

  void _cachePollLocally(Map<String, dynamic> poll) {
    final state = _postState;
    if (state == null) return;
    final latest = Map<String, dynamic>.from(state.latestPostData.value ?? {});
    latest['poll'] = Map<String, dynamic>.from(poll);
    state.latestPostData.value = latest;
  }

  int? _extractUserVoteFromPoll(Map<String, dynamic> poll) {
    final uid = _currentUid;
    if (uid.isEmpty) return null;
    final userVotes = poll['userVotes'] is Map
        ? Map<String, dynamic>.from(poll['userVotes'])
        : <String, dynamic>{};
    final raw = userVotes[uid];
    return raw is num ? raw.toInt() : int.tryParse('${raw ?? ''}');
  }

  void _syncLocalPollSelectionFromPoll(Map<String, dynamic> poll) {
    final selection = _extractUserVoteFromPoll(poll);
    _localPollSelection.value = selection;
    _postState?.localPollSelection.value = selection;
    final uid = _currentUid;
    if (uid.isEmpty) return;
    if (selection == null) {
      if (DateTime.now().millisecondsSinceEpoch >= _pollExpiresAtMs(poll)) {
        unawaited(_postRepository.clearLocalPollSelection(
          postId: model.docID,
          currentUid: uid,
        ));
      }
      return;
    }
    unawaited(_postRepository.persistLocalPollSelection(
      postId: model.docID,
      currentUid: uid,
      optionIndex: selection,
      expiresAtMs: _pollExpiresAtMs(poll),
    ));
  }

  Future<void> _restorePersistedPollSelectionIfNeeded() async {
    final uid = _currentUid;
    if (uid.isEmpty || model.poll.isEmpty) return;
    final currentPoll = Map<String, dynamic>.from(model.poll);
    final remoteSelection = _extractUserVoteFromPoll(currentPoll);
    if (remoteSelection != null) {
      await _postRepository.persistLocalPollSelection(
        postId: model.docID,
        currentUid: uid,
        optionIndex: remoteSelection,
        expiresAtMs: _pollExpiresAtMs(currentPoll),
      );
      return;
    }
    final cachedSelection = await _postRepository.readLocalPollSelection(
      postId: model.docID,
      currentUid: uid,
    );
    if (cachedSelection == null) return;
    final optimisticPoll = _postRepository.buildVotedPoll(
      poll: currentPoll,
      optionIndex: cachedSelection,
      fallbackTimestampMs: model.timeStamp.toInt(),
      currentUid: uid,
    );
    _localPollSelection.value = cachedSelection;
    _postState?.localPollSelection.value = cachedSelection;
    if (optimisticPoll != null) {
      model.poll = optimisticPoll;
      _cachePollLocally(optimisticPoll);
    }
    currentModel.refresh();
  }

  bool _shouldIgnoreStaleIncomingPoll(Map<String, dynamic> incomingPoll) {
    final uid = _currentUid;
    if (uid.isEmpty) return false;

    final incomingUserVotes = incomingPoll['userVotes'] is Map
        ? Map<String, dynamic>.from(incomingPoll['userVotes'])
        : <String, dynamic>{};

    return _cachedPollSelection != null && !incomingUserVotes.containsKey(uid);
  }

  void _bindFollowingState() {
    if (isCurrentUserId(model.userID)) {
      isFollowing.value = true;
      return;
    }

    void syncFromAgenda() {
      isFollowing.value = agendaController.followingIDs.contains(model.userID);
    }

    syncFromAgenda();
    _followingWorker?.dispose();
    _followingWorker = ever<Set<String>>(agendaController.followingIDs, (_) {
      syncFromAgenda();
    });
  }

  void _bindMembershipListeners() {
    _postState = _postRepository.attachPost(model);
    final initialSelection =
        _postState?.localPollSelection.value ?? _extractUserVoteFromPoll(model.poll);
    _localPollSelection.value = initialSelection;
    _postState?.localPollSelection.value = initialSelection;
    unawaited(_restorePersistedPollSelectionIfNeeded());
    _syncSharedInteractionState();
    _interactionWorker?.dispose();
    _myResharesWorker?.dispose();
    if (_postState != null) {
      _interactionWorker = everAll([
        _postState!.liked,
        _postState!.saved,
        _postState!.reshared,
        _postState!.commented,
      ], (_) {
        _syncSharedInteractionState();
      });
    }
    _myResharesWorker =
        ever<Map<String, int>>(agendaController.myReshares, (_) {
      _syncSharedInteractionState();
    });
  }

  void _bindPostDocCounts() {
    _postDataWorker?.dispose();
    if (_postState == null) return;
    _postDataWorker =
        ever<Map<String, dynamic>?>(_postState!.latestPostData, (data) {
      if (data == null) return;
      final rawEditTime = data['editTime'];
      if (rawEditTime is num) {
        editTime.value = rawEditTime.toInt();
      } else if (rawEditTime is String) {
        editTime.value = int.tryParse(rawEditTime) ?? editTime.value;
      }

      final latestAuthorNickname = (data['authorNickname'] ??
              (data['author'] is Map
                  ? (data['author'] as Map)['nickname']
                  : null) ??
              '')
          .toString()
          .trim();
      final nicknameNeedsFallback = nickname.value.trim().isEmpty;
      if (latestAuthorNickname.isNotEmpty &&
          nicknameNeedsFallback &&
          latestAuthorNickname != nickname.value) {
        nickname.value = latestAuthorNickname;
        if (username.value.trim().isEmpty) {
          username.value = latestAuthorNickname;
        }
      }
      final latestAuthorAvatar = (data['authorAvatarUrl'] ??
              (data['author'] is Map
                  ? (data['author'] as Map)['avatarUrl']
                  : null) ??
              '')
          .toString()
          .trim();
      if (latestAuthorAvatar.isNotEmpty) {
        final resolved = resolveAvatarUrl({'avatarUrl': latestAuthorAvatar});
        if (resolved != avatarUrl.value) {
          avatarUrl.value = resolved;
        }
      }

      if (data['poll'] != null) {
        try {
          final incomingPoll = Map<String, dynamic>.from(data['poll']);
          if (_shouldIgnoreStaleIncomingPoll(incomingPoll)) {
            return;
          }
          model.poll = incomingPoll;
          _syncLocalPollSelectionFromPoll(incomingPoll);
          currentModel.refresh();
        } catch (_) {}
      }

      final rawStats = data['stats'];
      dynamic rawRetryCount;
      if (rawStats is Map) {
        rawRetryCount = rawStats['retryCount'];
      }
      rawRetryCount ??= data['retryCount'];
      if (rawRetryCount != null) {
        final parsedRetryCount = rawRetryCount is num
            ? rawRetryCount.toInt()
            : int.tryParse('$rawRetryCount');
        if (parsedRetryCount != null) {
          model.stats.retryCount = parsedRetryCount;
          final retryRx = countManager.getRetryCount(model.docID);
          if (retryRx.value != parsedRetryCount) {
            retryRx.value = parsedRetryCount;
          }
        }
      }
    });
  }

  void _syncSharedInteractionState() {
    final uid = _currentUid;
    if (_postState == null) return;
    final liked = _postState!.liked.value;
    if (uid.isNotEmpty) {
      if (liked) {
        if (!likes.contains(uid)) likes.add(uid);
      } else {
        likes.remove(uid);
      }
    }
    saved.value = _postState!.saved.value;
    yenidenPaylasildiMi.value = _postState!.reshared.value ||
        agendaController.myReshares.containsKey(reshareTargetPostId);
    if (uid.isNotEmpty) {
      if (_postState!.commented.value) {
        if (!comments.contains(uid)) comments.add(uid);
      } else {
        comments.remove(uid);
      }
    }
  }

  Future<void> votePoll(int optionIndex) async {
    final uid = _currentUid;
    if (uid.isEmpty) return;
    final originalPoll = Map<String, dynamic>.from(model.poll);
    final optimisticPoll = _postRepository.buildVotedPoll(
      poll: originalPoll,
      optionIndex: optionIndex,
      fallbackTimestampMs: model.timeStamp.toInt(),
      currentUid: uid,
    );
    if (optimisticPoll == null) return;
    try {
      _localPollSelection.value = optionIndex;
      _postState?.localPollSelection.value = optionIndex;
      model.poll = optimisticPoll;
      _cachePollLocally(optimisticPoll);
      unawaited(_postRepository.persistLocalPollSelection(
        postId: model.docID,
        currentUid: uid,
        optionIndex: optionIndex,
        expiresAtMs: _pollExpiresAtMs(optimisticPoll),
      ));
      currentModel.refresh();
      final confirmedPoll = await _postRepository.commitPollVote(
        postId: model.docID,
        optionIndex: optionIndex,
        fallbackTimestampMs: model.timeStamp.toInt(),
        currentUid: uid,
      );
      if (confirmedPoll != null) {
        _syncLocalPollSelectionFromPoll(confirmedPoll);
        model.poll = confirmedPoll;
        _cachePollLocally(confirmedPoll);
      }
      currentModel.refresh();
    } catch (_) {
      currentModel.refresh();
    }
  }

  void _initializeStats() {
    likeCount.value = model.stats.likeCount.toInt();
    commentCount.value = model.stats.commentCount.toInt();
    savedCount.value = model.stats.savedCount.toInt();
    retryCount.value = model.stats.retryCount.toInt();
    statsCount.value = model.stats.statsCount.toInt();
  }
}
