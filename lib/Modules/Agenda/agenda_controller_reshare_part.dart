part of 'agenda_controller.dart';

extension AgendaControllerResharePart on AgendaController {
  Future<void> _fetchFollowingAndReshares(
    String uid, {
    bool refreshFollowings = false,
  }) async {
    try {
      final followings = await FollowRepository.ensure().getFollowingIds(
        uid,
        preferCache: true,
        forceRefresh: refreshFollowings,
      );
      followingIDs.assignAll(followings);
    } catch (_) {}

    try {
      myReshares.value = await _postRepository.fetchUserResharedPosts(
        uid,
        preferCache: true,
        forceRefresh: refreshFollowings,
        limit: 200,
      );
    } catch (_) {}
  }

  Future<void> refreshFollowingData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _fetchFollowingAndReshares(uid, refreshFollowings: true);
  }

  Future<void> fetchResharesForPosts(
    List<PostsModel> posts, {
    int perPostLimit = 2,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final targetPosts =
          posts.take(AgendaController._reshareScanPostLimit).toList();
      if (targetPosts.isEmpty) return;

      final existingKeys = publicReshareEvents
          .map((e) => '${e['postID']}::${e['userID']}')
          .toSet();
      final buffered = <Map<String, dynamic>>[];
      final maybeUnknownUsers = <String>{};

      for (final p in targetPosts) {
        try {
          final entries = await _postRepository.fetchAllReshareEntries(
            p.docID,
            limit: perPostLimit,
          );
          for (final entry in entries) {
            if (entry.quotedPost) continue;
            final rid = entry.userId;
            if (uid != null && rid == uid) continue;
            final key = '${p.docID}::$rid';
            if (existingKeys.contains(key)) continue;
            final ts = entry.timeStamp;
            final originalUserID = p.originalUserID.trim().isNotEmpty
                ? p.originalUserID
                : p.userID;
            final originalPostID =
                p.originalPostID.trim().isNotEmpty ? p.originalPostID : p.docID;
            if (!followingIDs.contains(rid) &&
                !_userPrivacyCache.containsKey(rid)) {
              maybeUnknownUsers.add(rid);
            }

            final reshareEvent = {
              'postID': p.docID,
              'userID': rid,
              'timeStamp': ts,
              'type': 'reshare',
            };

            if (originalUserID.isNotEmpty) {
              reshareEvent['originalUserID'] = originalUserID;
              reshareEvent['originalPostID'] = originalPostID;
            } else {
              reshareEvent['originalUserID'] = p.userID;
              reshareEvent['originalPostID'] = p.docID;
            }

            buffered.add(reshareEvent);
            existingKeys.add(key);
          }
        } catch (_) {}
      }

      await _warmPrivacyCacheForUsers(maybeUnknownUsers.toList());

      for (final event in buffered) {
        final rid = (event['userID'] ?? '').toString();
        if (rid.isEmpty) continue;
        if (followingIDs.contains(rid)) {
          publicReshareEvents.add(event);
          continue;
        }
        final isPrivate = _userPrivacyCache[rid] ?? false;
        if (!isPrivate) {
          publicReshareEvents.add(event);
        }
      }
    } catch (_) {}
  }

  void _addUniqueToAgenda(List<PostsModel> items) {
    if (items.isEmpty) return;
    final existing = agendaList.map((e) => e.docID).toSet();
    final unique = <PostsModel>[];
    for (final p in items) {
      if (!existing.contains(p.docID)) {
        existing.add(p.docID);
        unique.add(p);
      }
    }
    if (unique.isNotEmpty) {
      agendaList.addAll(unique);
      _scheduleFeedPrefetch();
    }
  }

  Future<bool> _isUserPrivate(String userID) async {
    if (_userPrivacyCache.containsKey(userID)) {
      return _userPrivacyCache[userID]!;
    }
    try {
      final data = await _profileCache.getProfile(
        userID,
        preferCache: true,
        cacheOnly: !ContentPolicy.isConnected,
      );
      final gizli = (data?['isPrivate'] ?? false) == true;
      _userDeactivatedCache[userID] = _isUserMarkedDeactivated(data);
      _userPrivacyCache[userID] = gizli;
      return gizli;
    } catch (_) {
      _userPrivacyCache[userID] = false;
      _userDeactivatedCache[userID] = false;
      return false;
    }
  }

  bool _isUserMarkedDeactivated(Map<String, dynamic>? data) {
    if (data == null) return false;
    final deletedAccount = (data['isDeleted'] ?? false) == true;
    final status = (data['accountStatus'] ?? '').toString().toLowerCase();
    return deletedAccount ||
        status == 'pending_deletion' ||
        status == 'deleted';
  }

  Future<bool> _isUserDeactivated(String userID) async {
    if (_userDeactivatedCache.containsKey(userID)) {
      return _userDeactivatedCache[userID]!;
    }
    try {
      final data = await _profileCache.getProfile(
        userID,
        preferCache: true,
        cacheOnly: !ContentPolicy.isConnected,
      );
      final deactivated = _isUserMarkedDeactivated(data);
      _userDeactivatedCache[userID] = deactivated;
      _userPrivacyCache[userID] = (data?['isPrivate'] ?? false) == true;
      return deactivated;
    } catch (_) {
      _userDeactivatedCache[userID] = false;
      return false;
    }
  }

  Future<void> _warmPrivacyCacheForUsers(List<String> userIds) async {
    final unresolved = userIds
        .where(
          (id) =>
              id.isNotEmpty &&
              (!_userPrivacyCache.containsKey(id) ||
                  !_userDeactivatedCache.containsKey(id)),
        )
        .toSet()
        .toList();
    if (unresolved.isEmpty) return;
    final profiles = await _userRepository.getUsersRaw(
      unresolved,
      preferCache: true,
      cacheOnly: !ContentPolicy.isConnected,
    );
    for (final id in unresolved) {
      final data = profiles[id];
      if (data == null) {
        _userPrivacyCache[id] = false;
        _userDeactivatedCache[id] = false;
        continue;
      }
      _userPrivacyCache[id] = (data['isPrivate'] ?? false) == true;
      _userDeactivatedCache[id] = _isUserMarkedDeactivated(data);
    }
  }

  List<String> _primeAgendaUserStateFromCaches(
    List<String> userIds,
    Map<String, bool> userPrivacy,
    Map<String, bool> userDeactivated,
    Map<String, Map<String, dynamic>> userMeta,
  ) {
    final unresolved = <String>[];
    for (final uid in userIds) {
      if (uid.isEmpty) continue;
      final cachedProfile = _profileCache.peekProfile(uid, allowStale: true);
      if (cachedProfile != null) {
        final isPrivate = (cachedProfile['isPrivate'] ?? false) == true;
        final isDeactivated = _isUserMarkedDeactivated(cachedProfile);
        userPrivacy[uid] = isPrivate;
        userDeactivated[uid] = isDeactivated;
        _userPrivacyCache[uid] = isPrivate;
        _userDeactivatedCache[uid] = isDeactivated;
        userMeta[uid] = cachedProfile;
        continue;
      }

      final cachedPrivacy = _userPrivacyCache[uid];
      final cachedDeactivated = _userDeactivatedCache[uid];
      if (cachedPrivacy != null && cachedDeactivated != null) {
        userPrivacy[uid] = cachedPrivacy;
        userDeactivated[uid] = cachedDeactivated;
        continue;
      }

      unresolved.add(uid);
    }
    return unresolved;
  }

  Future<void> _fillAgendaUserStateFromProfiles(
    List<String> userIds,
    Map<String, bool> userPrivacy,
    Map<String, bool> userDeactivated,
    Map<String, Map<String, dynamic>> userMeta, {
    bool includeMeta = true,
  }) async {
    final unresolved = userIds.where((id) => id.isNotEmpty).toSet().toList();
    if (unresolved.isEmpty) return;

    final profiles = await _profileCache.getProfiles(
      unresolved,
      preferCache: true,
      cacheOnly: !ContentPolicy.isConnected,
    );
    for (final uid in unresolved) {
      final data = profiles[uid];
      if (data == null) {
        userPrivacy[uid] = false;
        userDeactivated[uid] = false;
        _userPrivacyCache[uid] = false;
        _userDeactivatedCache[uid] = false;
        continue;
      }
      final isPrivate = (data['isPrivate'] ?? false) == true;
      final isDeactivated = _isUserMarkedDeactivated(data);
      userPrivacy[uid] = isPrivate;
      userDeactivated[uid] = isDeactivated;
      _userPrivacyCache[uid] = isPrivate;
      _userDeactivatedCache[uid] = isDeactivated;
      if (includeMeta) {
        userMeta[uid] = data;
      }
    }
  }

  void addUploadedPostsAtTop(List<PostsModel> posts) {
    if (posts.isEmpty) return;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final existingIDs = agendaList.map((e) => e.docID).toSet();
    final toAdd = <PostsModel>[];
    for (final p in posts) {
      if (!existingIDs.contains(p.docID) &&
          !hiddenPosts.contains(p.docID) &&
          _isInAgendaWindow(p.timeStamp, nowMs) &&
          _isRenderablePost(p)) {
        toAdd.add(p);
      }
    }
    if (toAdd.isEmpty) return;
    agendaList.insertAll(0, toAdd);
    _preloadOriginalUserNicknames(toAdd);
  }

  void _preloadOriginalUserNicknames(List<PostsModel> posts) {
    final userIDsToLoad = <String>{};

    for (final post in posts) {
      userIDsToLoad.add(post.userID);
      if (post.originalUserID.isNotEmpty) {
        userIDsToLoad.add(post.originalUserID);
      }
    }

    for (final userID in userIDsToLoad) {
      ReshareHelper.getUserNickname(userID).catchError((_) {
        return 'Bilinmeyen Kullanıcı';
      });
    }
  }

  Future<void> _fetchAndMergeReshareEvents({int eventLimit = 500}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final allReshareEvents = <Map<String, dynamic>>[];
      final reshareUserIds = <String>{};

      final rawEvents =
          await _postRepository.fetchCollectionGroupReshares(limit: eventLimit);
      for (final data in rawEvents) {
        final postId = (data['postID'] ?? '').toString();
        if (postId.isEmpty) continue;
        final reshareUserId = (data['userID'] ?? '').toString();
        if (reshareUserId.isEmpty) continue;
        final timestamp = (data['timeStamp'] as num?)?.toInt() ?? 0;
        final originalUserID = (data['originalUserID'] ?? '').toString();
        final originalPostID = (data['originalPostID'] ?? '').toString();

        allReshareEvents.add({
          'postID': postId,
          'userID': reshareUserId,
          'timeStamp': timestamp,
          'originalUserID': originalUserID,
          'originalPostID': originalPostID,
          'type': 'reshare',
        });
        reshareUserIds.add(reshareUserId);
      }

      await _warmPrivacyCacheForUsers(reshareUserIds.toList());

      final visibleEvents = allReshareEvents.where((event) {
        final reshareUserId = (event['userID'] ?? '').toString();
        if (reshareUserId.isEmpty) return false;
        if (reshareUserId == uid) return true;
        if (followingIDs.contains(reshareUserId)) return true;
        final isPrivate = _userPrivacyCache[reshareUserId] ?? false;
        final isDeactivated = _userDeactivatedCache[reshareUserId] ?? false;
        return !isPrivate && !isDeactivated;
      }).toList()
        ..sort((a, b) => ((b['timeStamp'] ?? 0) as int)
            .compareTo((a['timeStamp'] ?? 0) as int));

      if (visibleEvents.length > 120) {
        visibleEvents.removeRange(120, visibleEvents.length);
      }

      final visibleUserIds = visibleEvents
          .map((event) => (event['userID'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
      for (final userId in visibleUserIds) {
        unawaited(ReshareHelper.getUserNickname(userId));
      }

      final visiblePostIds = visibleEvents
          .map((event) => (event['postID'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();
      if (visiblePostIds.isEmpty) return;

      final postsById = <String, PostsModel>{};
      for (final batch in _chunkList(visiblePostIds, 10)) {
        try {
          final batchPosts = await _postRepository.fetchPostCardsByIds(
            batch,
            preferCache: true,
          );
          for (final post in batchPosts.values) {
            if (!await _canViewerSeePost(post)) continue;
            postsById[post.docID] = post;
          }
        } catch (e) {
          print('Error fetching reshare posts: $e');
        }
      }

      for (final event in visibleEvents) {
        final postId = (event['postID'] ?? '').toString();
        final post = postsById[postId];
        if (post == null) continue;

        final feedEntry = {
          'type': 'reshare',
          'post': post,
          'reshareTimestamp': event['timeStamp'],
          'reshareUserID': event['userID'],
          'originalUserID': event['originalUserID'],
          'originalPostID': event['originalPostID'],
        };

        final entryId =
            '${post.docID}_${event['userID']}_${event['timeStamp']}';
        final exists = feedReshareEntries.any((entry) {
          final existingId =
              '${(entry['post'] as PostsModel).docID}_${entry['reshareUserID']}_${entry['reshareTimestamp']}';
          return existingId == entryId;
        });
        if (!exists) {
          feedReshareEntries.add(feedEntry);
        }

        final metaKey = '${event['postID']}::${event['userID']}';
        final metaExists = publicReshareEvents.any(
          (existing) =>
              '${existing['postID']}::${existing['userID']}' == metaKey,
        );
        if (!metaExists) {
          publicReshareEvents.add(event);
        }
      }
    } catch (e) {
      print('_fetchAndMergeReshareEvents error: $e');
    }
  }

  Future<void> updateReshareEntries() async {
    try {
      feedReshareEntries.clear();
      await _fetchAndMergeReshareEvents();
    } catch (e) {
      print('updateReshareEntries error: $e');
    }
  }

  Future<void> addNewReshareEntry(String postId, String reshareUserID) async {
    try {
      final post = agendaList.firstWhereOrNull((p) => p.docID == postId);
      if (post == null) {
        final fetchedPost = await _postRepository.fetchPostById(
          postId,
          preferCache: true,
        );
        if (fetchedPost == null) return;
        if (!await _canViewerSeePost(fetchedPost)) return;

        final reshareEntry = {
          'type': 'reshare',
          'post': fetchedPost,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': fetchedPost.originalUserID.isNotEmpty
              ? fetchedPost.originalUserID
              : fetchedPost.userID,
          'originalPostID': fetchedPost.originalPostID.isNotEmpty
              ? fetchedPost.originalPostID
              : fetchedPost.docID,
        };

        feedReshareEntries.insert(0, reshareEntry);
      } else {
        if (!await _canViewerSeePost(post)) return;
        final reshareEntry = {
          'type': 'reshare',
          'post': post,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': post.originalUserID.isNotEmpty
              ? post.originalUserID
              : post.userID,
          'originalPostID':
              post.originalPostID.isNotEmpty ? post.originalPostID : post.docID,
        };

        feedReshareEntries.insert(0, reshareEntry);
      }
    } catch (e) {
      print('addNewReshareEntry error: $e');
    }
  }

  Future<void> addNewReshareEntryWithoutScroll(
    String postId,
    String reshareUserID,
  ) async {
    try {
      final currentOffset =
          scrollController.hasClients ? scrollController.offset : 0.0;
      final post = agendaList.firstWhereOrNull((p) => p.docID == postId);
      if (post == null) {
        final fetchedPost = await _postRepository.fetchPostById(
          postId,
          preferCache: true,
        );
        if (fetchedPost == null) return;
        if (!await _canViewerSeePost(fetchedPost)) return;

        final reshareEntry = {
          'type': 'reshare',
          'post': fetchedPost,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': fetchedPost.originalUserID.isNotEmpty
              ? fetchedPost.originalUserID
              : fetchedPost.userID,
          'originalPostID': fetchedPost.originalPostID.isNotEmpty
              ? fetchedPost.originalPostID
              : fetchedPost.docID,
        };

        feedReshareEntries.insert(0, reshareEntry);
      } else {
        if (!await _canViewerSeePost(post)) return;
        final reshareEntry = {
          'type': 'reshare',
          'post': post,
          'reshareTimestamp': DateTime.now().millisecondsSinceEpoch,
          'reshareUserID': reshareUserID,
          'originalUserID': post.originalUserID.isNotEmpty
              ? post.originalUserID
              : post.userID,
          'originalPostID':
              post.originalPostID.isNotEmpty ? post.originalPostID : post.docID,
        };

        feedReshareEntries.insert(0, reshareEntry);
      }

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (scrollController.hasClients) {
          await scrollController.animateTo(
            currentOffset,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      print('addNewReshareEntryWithoutScroll error: $e');
    }
  }

  void removeReshareEntry(String postId, String reshareUserID) {
    try {
      feedReshareEntries.removeWhere((entry) {
        final entryPost = entry['post'] as PostsModel;
        final entryUserID = (entry['reshareUserID'] ?? '').toString();
        final entryOriginalPostID =
            (entry['originalPostID'] ?? '').toString().trim();
        final entryPostID = entryPost.docID.trim();
        final normalizedTarget = postId.trim();
        final matchesPost = entryPostID == normalizedTarget ||
            entryOriginalPostID == normalizedTarget ||
            entryPost.originalPostID.trim() == normalizedTarget;
        final matchesUser = entryUserID == reshareUserID;
        return matchesPost && matchesUser;
      });
      feedReshareEntries.refresh();
    } catch (e) {
      print('removeReshareEntry error: $e');
    }
  }
}
