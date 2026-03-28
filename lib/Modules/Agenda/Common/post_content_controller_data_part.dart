part of 'post_content_controller.dart';

extension PostContentControllerDataPart on PostContentController {
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
          model.poll = Map<String, dynamic>.from(data['poll']);
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
      model.poll = optimisticPoll;
      currentModel.refresh();
      final confirmedPoll = await _postRepository.commitPollVote(
        postId: model.docID,
        optionIndex: optionIndex,
        fallbackTimestampMs: model.timeStamp.toInt(),
        currentUid: uid,
      );
      if (confirmedPoll == null) {
        model.poll = originalPoll;
      } else {
        model.poll = confirmedPoll;
      }
      currentModel.refresh();
    } catch (_) {
      model.poll = originalPoll;
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
