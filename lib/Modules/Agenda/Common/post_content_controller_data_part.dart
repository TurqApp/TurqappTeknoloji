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
          currentModel.value = model;
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
    final postRef =
        FirebaseFirestore.instance.collection('Posts').doc(model.docID);

    final originalPoll = Map<String, dynamic>.from(model.poll);
    try {
      final localPoll = Map<String, dynamic>.from(model.poll);
      if (localPoll.isEmpty) return;
      final createdAt = (localPoll['createdDate'] ?? model.timeStamp) as num;
      final durationHours = (localPoll['durationHours'] ?? 24) as num;
      final expiresAt =
          createdAt.toInt() + (durationHours.toInt() * 3600 * 1000);
      if (DateTime.now().millisecondsSinceEpoch > expiresAt) return;

      final options = (localPoll['options'] is List)
          ? List<Map<String, dynamic>>.from(
              (localPoll['options'] as List)
                  .map((o) => Map<String, dynamic>.from(o)),
            )
          : <Map<String, dynamic>>[];
      if (optionIndex < 0 || optionIndex >= options.length) return;

      final userVotes = localPoll['userVotes'] is Map
          ? Map<String, dynamic>.from(localPoll['userVotes'])
          : <String, dynamic>{};
      if (userVotes.containsKey(uid)) return;

      final opt = Map<String, dynamic>.from(options[optionIndex]);
      final currentVotes = (opt['votes'] ?? 0) as num;
      opt['votes'] = currentVotes.toInt() + 1;
      options[optionIndex] = opt;

      final totalVotes = (localPoll['totalVotes'] ?? 0) as num;
      localPoll['totalVotes'] = totalVotes.toInt() + 1;
      userVotes[uid] = optionIndex;
      localPoll['options'] = options;
      localPoll['userVotes'] = userVotes;

      model.poll = localPoll;
      currentModel.value = model;

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(postRef);
        final data = snap.data();
        if (data == null) return;
        final poll = Map<String, dynamic>.from(data['poll'] ?? {});
        if (poll.isEmpty) return;

        final createdAt =
            (poll['createdDate'] ?? data['timeStamp'] ?? 0) as num;
        final durationHours = (poll['durationHours'] ?? 24) as num;
        final expiresAt =
            createdAt.toInt() + (durationHours.toInt() * 3600 * 1000);
        if (DateTime.now().millisecondsSinceEpoch > expiresAt) return;

        final options = (poll['options'] is List)
            ? List<Map<String, dynamic>>.from(
                (poll['options'] as List)
                    .map((o) => Map<String, dynamic>.from(o)),
              )
            : <Map<String, dynamic>>[];
        if (optionIndex < 0 || optionIndex >= options.length) return;

        final userVotes = poll['userVotes'] is Map
            ? Map<String, dynamic>.from(poll['userVotes'])
            : <String, dynamic>{};
        if (userVotes.containsKey(uid)) return;

        final opt = Map<String, dynamic>.from(options[optionIndex]);
        final currentVotes = (opt['votes'] ?? 0) as num;
        opt['votes'] = currentVotes.toInt() + 1;
        options[optionIndex] = opt;

        final totalVotes = (poll['totalVotes'] ?? 0) as num;
        poll['totalVotes'] = totalVotes.toInt() + 1;
        userVotes[uid] = optionIndex;
        poll['options'] = options;
        poll['userVotes'] = userVotes;

        tx.update(postRef, {'poll': poll});
      });
    } catch (_) {
      model.poll = originalPoll;
      currentModel.value = model;
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
