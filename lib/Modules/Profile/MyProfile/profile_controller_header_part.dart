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

  String _preserveResolvedAvatar(
    Map<String, dynamic> data, {
    required Map<String, dynamic> profile,
  }) {
    final next = resolveAvatarUrl(data, profile: profile).trim();
    if (next.isNotEmpty) return next;
    return headerAvatarUrl.value.trim();
  }

  Future<void> _performBootstrapHeaderFromTypesense({
    bool allowBackgroundRefresh = true,
  }) async {
    final uid = _resolvedActiveUid;
    if (uid == null || uid.isEmpty) return;
    try {
      debugPrint(
        '[ProfileHeaderSource] source=firebase_user_cache manifest=disabled '
        'summary=disabled',
      );
      final cachedRaw = await _userRepository.getUserRaw(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      final bootstrapData = cachedRaw ?? const <String, dynamic>{};
      if (bootstrapData.isEmpty) return;
      _performApplyHeaderCard(bootstrapData);
      if (allowBackgroundRefresh &&
          _performNeedsHeaderSupplementalData(bootstrapData)) {
        final raw = await _userRepository.getUserRaw(
          uid,
          preferCache: false,
          forceServer: true,
        );
        if (raw != null && raw.isNotEmpty) {
          await _userRepository.putUserRaw(uid, raw);
          _performApplyHeaderCard(raw);
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
    final profile = (data['profile'] is Map)
        ? Map<String, dynamic>.from(data['profile'] as Map)
        : const <String, dynamic>{};
    final nextPostCount = (data['counterOfPosts'] as num?)?.toInt();
    final nextLikeCount = (data['counterOfLikes'] as num?)?.toInt();
    final nextFollowerCount = (data['counterOfFollowers'] as num?)?.toInt();
    final nextFollowingCount = (data['counterOfFollowings'] as num?)?.toInt();
    final nextListingCount = (data['counterOfListings'] as num?)?.toInt();
    if (nextPostCount != null) {
      postCount.value = nextPostCount;
    }
    if (nextLikeCount != null) {
      likeCount.value = nextLikeCount;
    }
    if (nextFollowerCount != null) {
      followerCount.value = nextFollowerCount;
    }
    if (nextFollowingCount != null) {
      followingCount.value = nextFollowingCount;
    }
    if (nextListingCount != null) {
      listingCount.value = nextListingCount;
    }
    headerNickname.value =
        _preserveNonEmpty(headerNickname, data['nickname'] ?? data['username']);
    headerRozet.value =
        _preserveNonEmpty(headerRozet, data['rozet'] ?? data['badge']);
    headerDisplayName.value =
        _preserveNonEmpty(headerDisplayName, data['displayName']);
    headerAvatarUrl.value = _preserveResolvedAvatar(data, profile: profile);

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

  Future<void> _performPrepareStartupSurface({
    bool? allowBackgroundRefresh,
  }) {
    final active = _startupPrepareFuture;
    if (active != null) {
      return active;
    }

    final future = _performRunPrepareStartupSurface(
      allowBackgroundRefresh: allowBackgroundRefresh,
    );
    _startupPrepareFuture = future;
    future.whenComplete(() {
      if (identical(_startupPrepareFuture, future)) {
        _startupPrepareFuture = null;
      }
    });
    return future;
  }

  Future<void> _performRunPrepareStartupSurface({
    bool? allowBackgroundRefresh,
  }) async {
    try {
      final allowRefresh = allowBackgroundRefresh ??
          ContentPolicy.allowBackgroundRefresh(ContentScreenKind.profile);

      await _performHydrateProfileStartupShard();
      await _performRestoreCachedListsForActiveUser();
      await _performBootstrapHeaderFromTypesense(
        allowBackgroundRefresh: allowRefresh,
      );

      if (!allowRefresh) {
        return;
      }

      unawaited(getCounters());
      _listenToCounterChanges();
      _bindResharesRealtime();
      unawaited(_loadInitialPrimaryBuckets());
      unawaited(getReshares());
    } finally {
      unawaited(_persistProfileStartupShard());
      unawaited(_recordProfileStartupSurface());
    }
  }

  Future<void> _performHydrateProfileStartupShard() async {
    _startupShardHydrated = false;
    _startupShardAgeMs = null;
    debugPrint(
      '[ProfileHeaderSource] startup_shard=disabled reason=posts_cache_only',
    );
  }

  Future<void> _persistProfileStartupShard() async {
    debugPrint(
      '[ProfileHeaderSource] persist_startup_shard=skip '
      'reason=posts_cache_only',
    );
  }

  Future<void> _recordProfileStartupSurface() async {
    debugPrint(
      '[ProfileHeaderSource] record_startup_surface=skip '
      'reason=posts_cache_only',
    );
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
          maybeFindSocialMediaController()?.getData(
                silent: true,
                forceRefresh: true,
              ) ??
              Future.value(),
        );
      },
    );
  }
}
