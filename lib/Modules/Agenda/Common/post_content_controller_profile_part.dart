part of 'post_content_controller.dart';

extension PostContentControllerProfilePart on PostContentController {
  void _clearResharePreviewState() {
    reSharedUsers.clear();
    reShareUserUserID.value = '';
    reShareUserNickname.value = '';
  }

  Future<void> followCheck() async {
    final currentUid = _currentUid;
    if (model.userID != currentUid) {
      if (agendaController.followingIDs.contains(model.userID)) {
        isFollowing.value = true;
        return;
      }
      final docExists = await ensureFollowRepository().isFollowing(
        model.userID,
        currentUid: currentUid,
        preferCache: true,
      );
      isFollowing.value = docExists;
      if (docExists) {
        agendaController.followingIDs.add(model.userID);
      }
    }
  }

  Future<void> getUserData(String userID) async {
    final postLevelNickname = model.authorNickname.trim();
    final postLevelDisplayName = model.authorDisplayName.trim();
    final postLevelAvatarFallback = model.authorAvatarUrl.trim();
    final hasPostLevelIdentity = postLevelNickname.isNotEmpty &&
        postLevelDisplayName.isNotEmpty &&
        postLevelAvatarFallback.isNotEmpty;

    void applyProfile({
      required String nick,
      required String uname,
      required String image,
      required String pushToken,
      required String name,
    }) {
      final rawImage = image.toString().trim();
      final shouldUsePostFallback = postLevelAvatarFallback.isNotEmpty &&
          (rawImage.isEmpty || rawImage == kDefaultAvatarUrl);
      final normalizedImage = shouldUsePostFallback
          ? postLevelAvatarFallback
          : (rawImage.isEmpty ? kDefaultAvatarUrl : rawImage);
      final effectiveNick =
          postLevelNickname.isNotEmpty ? postLevelNickname : nick;
      final effectiveName =
          postLevelDisplayName.isNotEmpty ? postLevelDisplayName : name;
      nickname.value = effectiveNick;
      username.value = uname.isNotEmpty ? uname : effectiveNick;
      avatarUrl.value = normalizedImage;
      token.value = pushToken;
      fullName.value = effectiveName;
    }

    void cacheProfile({
      required String uid,
      required String nick,
      required String uname,
      required String image,
      required String pushToken,
      required String name,
    }) {
      _userProfileCache[uid] = _UserProfileCacheEntry(
        nickname: nick,
        username: uname,
        avatarUrl: image,
        token: pushToken,
        fullName: name,
        updatedAt: DateTime.now(),
      );
    }

    void bindCurrentUserStream() {
      _currentUserStreamSub?.cancel();
      _currentUserStreamSub = userService.userStream.listen((user) {
        if (user == null || user.userID != userID) return;
        final currentUserDisplayName =
            user.fullName.trim().isNotEmpty ? user.fullName : user.nickname;
        final image = userService.avatarUrl;
        applyProfile(
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
        cacheProfile(
          uid: userID,
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
      });
    }

    final currentUserId = _currentUid;
    if (currentUserId == userID) {
      if (userService.currentUser != null) {
        final user = userService.currentUser!;
        final currentUserDisplayName =
            user.fullName.trim().isNotEmpty ? user.fullName : user.nickname;
        final image = userService.avatarUrl;
        applyProfile(
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
        cacheProfile(
          uid: userID,
          nick: user.nickname,
          uname: user.nickname,
          image: image,
          pushToken: user.token,
          name: currentUserDisplayName,
        );
        bindCurrentUserStream();
        return;
      }
      bindCurrentUserStream();
    }
    if (currentUserId != userID) {
      _currentUserStreamSub?.cancel();
      _currentUserStreamSub = null;
    }

    if (hasPostLevelIdentity) {
      applyProfile(
        nick: postLevelNickname,
        uname: postLevelNickname,
        image: postLevelAvatarFallback,
        pushToken: '',
        name: postLevelDisplayName,
      );
      return;
    }

    final cachedProfile = _userProfileCache[userID];
    if (cachedProfile != null &&
        DateTime.now().difference(cachedProfile.updatedAt) <
            _userProfileCacheTtl) {
      applyProfile(
        nick: cachedProfile.nickname,
        uname: cachedProfile.username,
        image: cachedProfile.avatarUrl,
        pushToken: cachedProfile.token,
        name: cachedProfile.fullName,
      );
      return;
    }

    final userSummaryResolver = UserSummaryResolver.ensure();
    final warmProfile = userSummaryResolver.peek(userID, allowStale: true);
    if (warmProfile != null) {
      applyProfile(
        nick: warmProfile.nickname,
        uname: warmProfile.username.isNotEmpty
            ? warmProfile.username
            : warmProfile.nickname,
        image: warmProfile.avatarUrl,
        pushToken: warmProfile.token,
        name: warmProfile.preferredName,
      );
      cacheProfile(
        uid: userID,
        nick: warmProfile.nickname,
        uname: warmProfile.username.isNotEmpty
            ? warmProfile.username
            : warmProfile.nickname,
        image: warmProfile.avatarUrl,
        pushToken: warmProfile.token,
        name: warmProfile.preferredName,
      );
      return;
    }

    try {
      final summary = await userSummaryResolver.resolve(
        userID,
        preferCache: true,
        cacheOnly: false,
      );
      if (summary != null) {
        applyProfile(
          nick: summary.nickname,
          uname:
              summary.username.isNotEmpty ? summary.username : summary.nickname,
          image: summary.avatarUrl,
          pushToken: summary.token,
          name: summary.preferredName,
        );
        cacheProfile(
          uid: userID,
          nick: summary.nickname,
          uname:
              summary.username.isNotEmpty ? summary.username : summary.nickname,
          image: summary.avatarUrl,
          pushToken: summary.token,
          name: summary.preferredName,
        );
      }
    } catch (_) {}
  }

  Future<void> getReSharedUsers(String docID) async {
    if (_currentUid.isEmpty) {
      _clearResharePreviewState();
      return;
    }

    final cached = _reshareUsersCache[docID];
    if (cached != null &&
        DateTime.now().difference(cached.updatedAt) < _reshareUsersCacheTtl) {
      reSharedUsers.value = cached.userIds;
      reShareUserUserID.value = cached.displayUserId;
      reShareUserNickname.value = cached.displayNickname;
      return;
    }

    List<PostReshareEntry> reshareEntries;
    try {
      reshareEntries = await _postRepository.fetchAllReshareEntries(
        docID,
        limit: ReadBudgetRegistry.reshareUserPreviewInitialLimit,
      );
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _clearResharePreviewState();
        return;
      }
      rethrow;
    }
    final entries =
        reshareEntries.map((e) => MapEntry(e.userId, e.timeStamp)).toList();
    final list = entries.map((e) => e.key).toList();
    reSharedUsers.value = list;

    final me = _currentUid;
    if (me.isNotEmpty && list.contains(me)) {
      reShareUserUserID.value = me;
      reShareUserNickname.value = 'Sen';
      _reshareUsersCache[docID] = _ReshareUsersCacheEntry(
        updatedAt: DateTime.now(),
        userIds: List<String>.from(list),
        displayUserId: me,
        displayNickname: 'Sen',
      );
      return;
    }

    try {
      final following = agendaController.followingIDs;
      final candidates = entries
          .where((e) => following.contains(e.key))
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (candidates.isNotEmpty) {
        final match = candidates.first.key;
        reShareUserUserID.value = match;
        final cached = ReshareHelper.getCachedNickname(match);
        if (cached != null) {
          reShareUserNickname.value = cached;
        } else {
          final nick = await ReshareHelper.getUserNickname(match);
          reShareUserNickname.value = nick;
        }
        _reshareUsersCache[docID] = _ReshareUsersCacheEntry(
          updatedAt: DateTime.now(),
          userIds: List<String>.from(list),
          displayUserId: match,
          displayNickname: reShareUserNickname.value,
        );
        return;
      }
    } catch (_) {}

    reShareUserUserID.value = '';
    reShareUserNickname.value = '';
    _reshareUsersCache[docID] = _ReshareUsersCacheEntry(
      updatedAt: DateTime.now(),
      userIds: List<String>.from(list),
      displayUserId: '',
      displayNickname: '',
    );
  }
}

class _UserProfileCacheEntry {
  final String nickname;
  final String username;
  final String avatarUrl;
  final String token;
  final String fullName;
  final DateTime updatedAt;

  const _UserProfileCacheEntry({
    required this.nickname,
    required this.username,
    required this.avatarUrl,
    required this.token,
    required this.fullName,
    required this.updatedAt,
  });
}

class _ReshareUsersCacheEntry {
  final DateTime updatedAt;
  final List<String> userIds;
  final String displayUserId;
  final String displayNickname;

  const _ReshareUsersCacheEntry({
    required this.updatedAt,
    required this.userIds,
    required this.displayUserId,
    required this.displayNickname,
  });
}
