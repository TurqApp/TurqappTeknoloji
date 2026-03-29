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

  Future<void> _performBootstrapProfileData() async {
    await _performPrepareStartupSurface();
  }

  Future<void> _performBootstrapHeaderFromTypesense({
    bool allowBackgroundRefresh = true,
  }) async {
    final uid = _resolvedActiveUid;
    if (uid == null || uid.isEmpty) return;
    try {
      final summary = await _userSummaryResolver.resolve(
        uid,
        preferCache: true,
        cacheOnly: !allowBackgroundRefresh,
      );
      final cachedRaw = await _userRepository.getUserRaw(
        uid,
        preferCache: true,
        cacheOnly: true,
      );
      final bootstrapData = cachedRaw ??
          (summary != null ? summary.toMap() : const <String, dynamic>{});
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
    final nextFollowerCount = (data['counterOfFollowers'] as num?)?.toInt() ??
        (data['followersCount'] as num?)?.toInt() ??
        (data['takipci'] as num?)?.toInt() ??
        (data['followerCount'] as num?)?.toInt();
    final nextFollowingCount = (data['counterOfFollowings'] as num?)?.toInt() ??
        (data['followingCount'] as num?)?.toInt() ??
        (data['takip'] as num?)?.toInt() ??
        (data['followCount'] as num?)?.toInt();
    if (nextFollowerCount != null) {
      followerCount.value = nextFollowerCount;
    }
    if (nextFollowingCount != null) {
      followingCount.value = nextFollowingCount;
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
    final userId = _resolvedActiveUid?.trim();
    if (userId == null || userId.isEmpty) return;
    _startupShardHydrated = false;
    _startupShardAgeMs = null;
    try {
      final shard = await ensureStartupSnapshotShardStore().load(
        surface: 'profile',
        userId: userId,
        maxAge: StartupSnapshotShardStore.defaultFreshWindow,
      );
      if (shard == null) return;
      var didHydrate = false;
      final header = _decodeProfileStartupHeader(shard.payload['header']);
      if (header.isNotEmpty) {
        _applyProfileStartupHeader(header);
        didHydrate = true;
      }
      if (allPosts.isEmpty) {
        final posts = _decodeProfileStartupPosts(shard.payload['allPosts']);
        if (posts.isNotEmpty) {
          allPosts.assignAll(posts);
          didHydrate = true;
        }
      }
      if (!didHydrate) return;
      _startupShardHydrated = true;
      _startupShardAgeMs =
          (DateTime.now().millisecondsSinceEpoch - shard.savedAtMs).toInt();
    } catch (_) {}
  }

  Future<void> _persistProfileStartupShard() async {
    final userId = _resolvedActiveUid?.trim();
    if (userId == null || userId.isEmpty) return;
    final payload = <String, dynamic>{
      'header': _encodeProfileStartupHeader(),
      'allPosts': _encodeProfileStartupPosts(
        allPosts.take(ReadBudgetRegistry.profileStartupShardLimit).toList(),
      ),
    };
    final hasHeader = (payload['header'] as Map<String, dynamic>).isNotEmpty;
    final hasPosts =
        ((payload['allPosts'] as Map<String, dynamic>)['items'] as List)
            .isNotEmpty;
    try {
      final store = ensureStartupSnapshotShardStore();
      if (!hasHeader && !hasPosts) {
        await store.clear(
          surface: 'profile',
          userId: userId,
        );
        return;
      }
      await store.save(
        surface: 'profile',
        userId: userId,
        itemCount: allPosts.length,
        limit: ReadBudgetRegistry.profileStartupShardLimit,
        source: hasPosts ? 'profile_snapshot' : 'user_summary',
        payload: payload,
      );
    } catch (_) {}
  }

  Future<void> _recordProfileStartupSurface() async {
    final userId = _resolvedActiveUid?.trim();
    if (userId == null || userId.isEmpty) return;
    final hasHeader = headerDisplayName.value.trim().isNotEmpty ||
        headerNickname.value.trim().isNotEmpty;
    final itemCount = allPosts.isNotEmpty
        ? allPosts.length
        : photos.isNotEmpty
            ? photos.length
            : videos.length;
    final hasLocalSnapshot = hasHeader || itemCount > 0;
    final source = itemCount > 0
        ? 'profile_snapshot'
        : hasHeader
            ? 'user_summary'
            : 'none';
    try {
      await ensureStartupSnapshotManifestStore().recordSurfaceState(
        surface: 'profile',
        userId: userId,
        itemCount: itemCount,
        hasLocalSnapshot: hasLocalSnapshot,
        source: source,
        startupShardHydrated: _startupShardHydrated,
        startupShardAgeMs: _startupShardAgeMs,
      );
    } catch (_) {}
  }

  Map<String, dynamic> _encodeProfileStartupHeader() {
    final payload = <String, dynamic>{
      'followerCount': followerCount.value,
      'followingCount': followingCount.value,
      'headerNickname': headerNickname.value.trim(),
      'headerRozet': headerRozet.value.trim(),
      'headerDisplayName': headerDisplayName.value.trim(),
      'headerAvatarUrl': headerAvatarUrl.value.trim(),
      'headerFirstName': headerFirstName.value.trim(),
      'headerLastName': headerLastName.value.trim(),
      'headerMeslek': headerMeslek.value.trim(),
      'headerBio': headerBio.value.trim(),
      'headerAdres': headerAdres.value.trim(),
    };
    payload.removeWhere((_, value) {
      if (value is String) return value.trim().isEmpty;
      if (value is num) return value == 0;
      return value == null;
    });
    return payload;
  }

  Map<String, dynamic> _decodeProfileStartupHeader(dynamic raw) {
    if (raw is! Map) return const <String, dynamic>{};
    return Map<String, dynamic>.from(raw.cast<dynamic, dynamic>());
  }

  void _applyProfileStartupHeader(Map<String, dynamic> header) {
    final nickname = (header['headerNickname'] ?? '').toString().trim();
    final displayName = (header['headerDisplayName'] ?? '').toString().trim();
    if (nickname.isNotEmpty) {
      headerNickname.value = nickname;
    }
    if (displayName.isNotEmpty) {
      headerDisplayName.value = displayName;
    }
    final rozet = (header['headerRozet'] ?? '').toString().trim();
    if (rozet.isNotEmpty) {
      headerRozet.value = rozet;
    }
    final avatarUrl = (header['headerAvatarUrl'] ?? '').toString().trim();
    if (avatarUrl.isNotEmpty) {
      headerAvatarUrl.value = avatarUrl;
    }
    final firstName = (header['headerFirstName'] ?? '').toString().trim();
    if (firstName.isNotEmpty) {
      headerFirstName.value = firstName;
    }
    final lastName = (header['headerLastName'] ?? '').toString().trim();
    if (lastName.isNotEmpty) {
      headerLastName.value = lastName;
    }
    final meslek = (header['headerMeslek'] ?? '').toString().trim();
    if (meslek.isNotEmpty) {
      headerMeslek.value = meslek;
    }
    final bio = (header['headerBio'] ?? '').toString().trim();
    if (bio.isNotEmpty) {
      headerBio.value = bio;
    }
    final adres = (header['headerAdres'] ?? '').toString().trim();
    if (adres.isNotEmpty) {
      headerAdres.value = adres;
    }
    final nextFollowerCount = (header['followerCount'] as num?)?.toInt();
    if (nextFollowerCount != null && nextFollowerCount > 0) {
      followerCount.value = nextFollowerCount;
    }
    final nextFollowingCount = (header['followingCount'] as num?)?.toInt();
    if (nextFollowingCount != null && nextFollowingCount > 0) {
      followingCount.value = nextFollowingCount;
    }
  }

  Map<String, dynamic> _encodeProfileStartupPosts(List<PostsModel> posts) {
    return <String, dynamic>{
      'items': posts
          .map(
            (post) => <String, dynamic>{
              'docID': post.docID,
              'data': post.toMap(),
            },
          )
          .toList(growable: false),
    };
  }

  List<PostsModel> _decodeProfileStartupPosts(dynamic raw) {
    if (raw is! Map) return const <PostsModel>[];
    final items = raw['items'];
    if (items is! List) return const <PostsModel>[];
    return items
        .whereType<Map>()
        .map((entry) {
          final map = Map<String, dynamic>.from(entry.cast<dynamic, dynamic>());
          final docId = (map['docID'] ?? '').toString().trim();
          final data = map['data'];
          if (docId.isEmpty || data is! Map) return null;
          try {
            return PostsModel.fromMap(
              Map<String, dynamic>.from(data.cast<dynamic, dynamic>()),
              docId,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<PostsModel>()
        .toList(growable: false);
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
