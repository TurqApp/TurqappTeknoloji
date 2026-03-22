part of 'profile_controller.dart';

extension ProfileControllerHeaderPart on ProfileController {
  String _preserveNonEmpty(
    RxString target,
    dynamic raw,
  ) {
    final next = (raw ?? '').toString().trim();
    if (next.isNotEmpty) return next;
    return target.value.trim();
  }

  Future<void> _performBootstrapProfileData() async {
    await _restoreCachedListsForActiveUser();
    await _bootstrapHeaderFromTypesense();
    getCounters();
    _listenToCounterChanges();
    _bindResharesRealtime();
    unawaited(_loadInitialPrimaryBuckets());
    getReshares();
  }

  Future<void> _performBootstrapHeaderFromTypesense() async {
    final uid = _resolvedActiveUid;
    if (uid == null || uid.isEmpty) return;
    try {
      final summary = await _userSummaryResolver.resolve(
        uid,
        preferCache: true,
        cacheOnly: false,
      );
      final cachedRaw = await _userRepository.getUserRaw(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      final bootstrapData = cachedRaw ??
          (summary != null ? summary.toMap() : const <String, dynamic>{});
      if (bootstrapData.isEmpty) return;
      _applyHeaderCard(bootstrapData);
      if (_needsHeaderSupplementalData(bootstrapData)) {
        final raw = await _userRepository.getUserRaw(
          uid,
          preferCache: false,
          forceServer: true,
        );
        if (raw != null && raw.isNotEmpty) {
          await _userRepository.putUserRaw(uid, raw);
          _applyHeaderCard(raw);
        }
      }
    } catch (e) {
      print('_bootstrapHeaderFromTypesense error: $e');
    }
  }

  bool _performNeedsHeaderSupplementalData(Map<String, dynamic> data) {
    final bioText = (data['bio'] ?? '').toString().trim();
    final addressText = (data['adres'] ?? '').toString().trim();
    final meslekText = (data['meslekKategori'] ?? '').toString().trim();
    return bioText.isEmpty || addressText.isEmpty || meslekText.isEmpty;
  }

  void _performApplyHeaderCard(Map<String, dynamic> data) {
    headerNickname.value =
        (data['nickname'] ?? data['username'] ?? '').toString().trim();
    headerRozet.value =
        (data['rozet'] ?? data['badge'] ?? '').toString().trim();
    headerDisplayName.value = (data['displayName'] ?? '').toString().trim();
    headerAvatarUrl.value = (data['avatarUrl'] ?? '').toString().trim();

    final display = headerDisplayName.value.trim();
    if (display.isNotEmpty) {
      headerFirstName.value = display;
      headerLastName.value = '';
    } else {
      headerFirstName.value =
          _preserveNonEmpty(headerFirstName, data['firstName']);
      headerLastName.value =
          _preserveNonEmpty(headerLastName, data['lastName']);
    }
    headerMeslek.value =
        _preserveNonEmpty(headerMeslek, data['meslekKategori']);
    headerBio.value = _preserveNonEmpty(headerBio, data['bio']);
    headerAdres.value = _preserveNonEmpty(headerAdres, data['adres']);
  }

  void _performListenToCounterChanges() {
    final uid = _resolvedActiveUid;
    if (uid == null) return;

    _counterSub?.cancel();

    _counterSub = _userRepository.watchUserRaw(uid).listen((snapshot) {
      final data = snapshot;
      if (data != null) {
        followerCount.value = (data['counterOfFollowers'] as num?)?.toInt() ??
            (data['followersCount'] as num?)?.toInt() ??
            (data['takipci'] as num?)?.toInt() ??
            (data['followerCount'] as num?)?.toInt() ??
            0;
        followingCount.value = (data['counterOfFollowings'] as num?)?.toInt() ??
            (data['followingCount'] as num?)?.toInt() ??
            (data['takip'] as num?)?.toInt() ??
            (data['followCount'] as num?)?.toInt() ??
            0;
      }
    });
  }

  void _performOnAuthChanged(User? user) {
    final newUid = user?.uid;
    if (newUid == null) {
      _activeUid = null;
      _counterSub?.cancel();
      _counterSub = null;
      try {
        allPosts.clear();
      } catch (_) {
        allPosts.value = [];
      }
      try {
        photos.clear();
      } catch (_) {
        photos.value = [];
      }
      try {
        videos.clear();
      } catch (_) {
        videos.value = [];
      }
      try {
        reshares.clear();
      } catch (_) {
        reshares.value = [];
      }
      try {
        scheduledPosts.clear();
      } catch (_) {
        scheduledPosts.value = [];
      }

      followerCount.value = 0;
      followingCount.value = 0;
      lastPostDoc = null;
      lastPostDocPhotos = null;
      lastPostDocVideos = null;
      lastScheduledDoc = null;
      hasMorePosts = true;
      hasMorePostsPhotos = true;
      hasMorePostsVideos = true;
      hasMoreScheduled = true;
      return;
    }

    if (newUid != _activeUid) {
      _activeUid = newUid;
      _clearInMemoryPostLists();
      _listenToCounterChanges();
      unawaited(_restoreCachedListsForActiveUser());
      refreshAll();
    }
  }

  Future<void> _performGetCounters() async {
    final uid = _resolvedActiveUid;
    if (uid == null) return;

    try {
      final data = await _userRepository.getUserRaw(
        uid,
        preferCache: true,
      );
      followerCount.value = (data?['counterOfFollowers'] as num?)?.toInt() ??
          (data?['followersCount'] as num?)?.toInt() ??
          (data?['takipci'] as num?)?.toInt() ??
          (data?['followerCount'] as num?)?.toInt() ??
          0;
      followingCount.value = (data?['counterOfFollowings'] as num?)?.toInt() ??
          (data?['followingCount'] as num?)?.toInt() ??
          (data?['takip'] as num?)?.toInt() ??
          (data?['followCount'] as num?)?.toInt() ??
          0;

      if (followerCount.value == 0 || followingCount.value == 0) {
        final followers = await _followRepository.getFollowerIds(
          uid,
          preferCache: true,
          forceRefresh: false,
        );
        final followings = await _visibilityPolicy.loadViewerFollowingIds(
          viewerUserId: uid,
          preferCache: true,
          forceRefresh: false,
        );
        followerCount.value = followers.length;
        followingCount.value = followings.length;
      }
    } catch (e) {
      print("⚠️ getCounters error: $e");
    }
  }

  Future<void> _performShowSocialMediaLinkDelete(String docID) async {
    await noYesAlert(
      title: "profile.link_remove_title".tr,
      message: "profile.link_remove_body".tr,
      cancelText: "common.cancel".tr,
      yesText: "common.remove".tr,
      onYesPressed: () async {
        final uid = _resolvedActiveUid;
        if (uid == null || uid.isEmpty) return;
        await _socialLinksRepository.deleteLink(uid, docID);
        unawaited(
          SocialMediaController.maybeFind()?.getData(
                silent: true,
                forceRefresh: true,
              ) ??
              Future.value(),
        );
      },
    );
  }
}
