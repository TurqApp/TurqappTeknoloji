part of 'agenda_controller.dart';

extension AgendaControllerSupportPart on AgendaController {
  UserProfileCacheService get _profileCache => ensureUserProfileCacheService();

  UserSummaryResolver get _userSummaryResolver => UserSummaryResolver.ensure();

  VisibilityPolicyService get _visibilityPolicy =>
      VisibilityPolicyService.ensure();

  PostRepository get _postRepository => PostRepository.ensure();

  FeedSnapshotRepository get _feedSnapshotRepository =>
      ensureFeedSnapshotRepository();

  FeedRenderCoordinator get _feedRenderCoordinator =>
      FeedRenderCoordinator.ensure();

  RuntimeInvariantGuard get _invariantGuard => ensureRuntimeInvariantGuard();

  bool _isRenderablePost(PostsModel post) {
    if (!post.hasVideoSignal) return true;
    return post.hasRenderableVideoCard;
  }

  bool canAutoplayInTests(PostsModel post) => _canAutoplayVideoPost(post);

  bool _isBlurredIzBirakVideo(PostsModel post, [int? nowMs]) {
    final scheduled = post.scheduledAt.toInt();
    if (scheduled <= 0 || post.video.trim().isEmpty) return false;
    final publishAt =
        scheduled > 0 ? scheduled : post.izBirakYayinTarihi.toInt();
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    return publishAt > now;
  }

  bool _canAutoplayVideoPost(PostsModel post, [int? nowMs]) {
    return post.hasPlayableVideo && !_isBlurredIzBirakVideo(post, nowMs);
  }

  bool get isPrimaryFeedRouteVisible {
    final route = Get.currentRoute.trim();
    if (route.isEmpty) return true;
    return route == '/NavBarView' || route == 'NavBarView';
  }

  bool get canClaimPlaybackNow {
    final nav = maybeFindNavBarController();
    if (nav != null && nav.selectedIndex.value != 0) return false;
    if (playbackSuspended.value) return false;
    if (!isPrimaryFeedRouteVisible) return false;
    return true;
  }

  Future<bool> _canViewerSeePost(PostsModel post) async {
    if (hiddenPosts.contains(post.docID)) return false;
    if (post.deletedPost == true) return false;
    if (!_isRenderablePost(post)) return false;
    if (await _isUserDeactivated(post.userID)) return false;

    final summary = await _userSummaryResolver.resolve(
      post.userID,
      preferCache: true,
    );
    if (summary == null) return false;
    return _visibilityPolicy.canViewerSeeDiscoveryAuthorFromSummary(
      authorUserId: post.userID,
      followingIds: followingIDs,
      rozet: summary.rozet,
      isApproved: summary.isApproved,
      isDeleted: summary.isDeleted,
    );
  }

  String get latestQAScrollToken => _qaLatestScrollToken;

  bool get isFollowingMode => feedViewMode.value == FeedViewMode.following;
  bool get isCityMode => feedViewMode.value == FeedViewMode.city;

  String get feedTitle {
    if (isFollowingMode) return 'agenda.following'.tr;
    if (isCityMode) return 'agenda.city'.tr;
    return 'app.name'.tr;
  }

  String get currentUserLocationCity {
    return CurrentUserService.instance.preferredLocationCity;
  }

  void setFeedViewMode(FeedViewMode mode) {
    if (feedViewMode.value == mode) return;
    feedViewMode.value = mode;
  }

  int _agendaCutoffMs(int nowMs) {
    if (_agendaWindow == null) return 0;
    return nowMs - _agendaWindow!.inMilliseconds;
  }

  bool _isInAgendaWindow(num ts, int nowMs) {
    if (_agendaWindow == null) return true;
    final v = ts.toInt();
    return v >= _agendaCutoffMs(nowMs) && v <= nowMs;
  }

  bool _isEligibleAgendaPost(PostsModel post, int nowMs) {
    final ts = post.timeStamp.toInt();
    if (_agendaWindow != null && ts < _agendaCutoffMs(nowMs)) {
      return false;
    }
    if (ts <= nowMs) {
      return true;
    }
    return post.scheduledAt.toInt() > 0;
  }

  Future<List<PostsModel>> _fetchVisiblePublicIzBirakPosts({
    required int nowMs,
    required int cutoffMs,
    int limit = 40,
    bool preferCache = true,
    bool cacheOnly = false,
  }) async {
    final effectivePreferCache = cacheOnly ? preferCache : false;
    final publicIzBirakPosts =
        await _postRepository.fetchPublicScheduledIzBirakPosts(
      nowMs: nowMs,
      cutoffMs: cutoffMs,
      limit: limit,
      preferCache: effectivePreferCache,
      cacheOnly: cacheOnly,
    );
    if (publicIzBirakPosts.isEmpty) return const <PostsModel>[];

    final authorMeta = await _userSummaryResolver.resolveMany(
      publicIzBirakPosts.map((p) => p.userID).toSet().toList(),
      preferCache: effectivePreferCache,
      cacheOnly: cacheOnly,
    );
    return publicIzBirakPosts.where((post) {
      final meta = authorMeta[post.userID];
      if (meta == null || meta.isDeleted) return false;
      return isDiscoveryPublicAuthor(
        rozet: meta.rozet,
        isApproved: meta.isApproved,
      );
    }).toList(growable: false);
  }
}

extension AgendaControllerPublicApiPart on AgendaController {
  Future<void> onPrimarySurfaceVisible() => prepareStartupSurface(
        allowBackgroundRefresh:
            ContentPolicy.allowBackgroundRefresh(ContentScreenKind.feed),
      );

  Future<void> prepareStartupSurface({
    bool? allowBackgroundRefresh,
  }) {
    final active = _startupPrepareFuture;
    if (active != null) {
      return active;
    }
    final future = _performPrepareStartupSurface(
      allowBackgroundRefresh: allowBackgroundRefresh,
    );
    _startupPrepareFuture = future;
    return future.whenComplete(() {
      if (identical(_startupPrepareFuture, future)) {
        _startupPrepareFuture = null;
      }
    });
  }

  Future<void> _performPrepareStartupSurface({
    bool? allowBackgroundRefresh,
  }) async {
    await ensureFeedSurfaceReady();
    await _recordFeedStartupSurface(
      source: 'feed_surface_ready',
    );
    final allowRefresh = allowBackgroundRefresh ??
        ContentPolicy.allowBackgroundRefresh(ContentScreenKind.feed);
    if (!allowRefresh || agendaList.isEmpty) return;
    unawaited(syncFeedHeadAfterSurfaceOpen());
  }

  Future<void> persistStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final ordered = _buildOrderedAgendaSnapshot(limit: 40);
    await _persistFeedStartupShardOnly(
      userId: userId,
      ordered: ordered,
      snapshotAt: DateTime.now(),
      source: 'feed_runtime',
    );
  }

  Future<void> persistStartupArtifacts() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final snapshotAt = DateTime.now();
    final ordered = _buildOrderedAgendaSnapshot(limit: 40);
    if (ordered.isEmpty) {
      await _persistFeedStartupShardOnly(
        userId: userId,
        ordered: ordered,
        snapshotAt: snapshotAt,
        source: 'none',
      );
      return;
    }
    await _feedSnapshotRepository.persistHomeSnapshot(
      userId: userId,
      posts: ordered,
      limit: 40,
      source: CachedResourceSource.memory,
      snapshotAt: snapshotAt,
    );
    await _persistFeedStartupShardOnly(
      userId: userId,
      ordered: ordered,
      snapshotAt: snapshotAt,
      source: 'feed_runtime',
    );
  }

  void onPostVisibilityChanged(int modelIndex, double visibleFraction) =>
      _performOnPostVisibilityChanged(modelIndex, visibleFraction);

  void suspendPlaybackForOverlay() => _performSuspendPlaybackForOverlay();

  void resumePlaybackAfterOverlay() => _performResumePlaybackAfterOverlay();

  void resetSurfaceForTabTransition() => _performResetSurfaceForTabTransition();

  void _scheduleVisibilityEvaluation({
    required double playThreshold,
    required double stopThreshold,
  }) =>
      _performScheduleVisibilityEvaluation(
        playThreshold: playThreshold,
        stopThreshold: stopThreshold,
      );

  void _evaluateCenteredPlayback({
    required double playThreshold,
    required double stopThreshold,
  }) =>
      _performEvaluateCenteredPlayback(
        playThreshold: playThreshold,
        stopThreshold: stopThreshold,
      );

  void _trackPlaybackWindow() => _performTrackPlaybackWindow();

  void _bindFollowingListener() => _performBindFollowingListener();

  void _bindMergedFeedEntries() => _performBindMergedFeedEntries();

  void _bindFilteredFeedEntries() => _performBindFilteredFeedEntries();

  void _bindRenderFeedEntries() => _performBindRenderFeedEntries();

  void _rebuildMergedFeedEntries() => _performRebuildMergedFeedEntries();

  void _rebuildFilteredFeedEntries() => _performRebuildFilteredFeedEntries();

  void _rebuildRenderFeedEntries() => _performRebuildRenderFeedEntries();

  Future<void> _recordFeedStartupSurface({
    required String source,
    int? itemCount,
  }) async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final count = itemCount ?? agendaList.length;
    bool startupShardHydrated = false;
    int? startupShardAgeMs;
    if (count > 0) {
      try {
        final existingManifest =
            await ensureStartupSnapshotManifestStore().load(userId: userId);
        final existingRecord = existingManifest?.surfaces['feed'];
        startupShardHydrated = existingRecord?.startupShardHydrated == true;
        startupShardAgeMs = existingRecord?.startupShardAgeMs;
      } catch (_) {}
    }
    await ensureStartupSnapshotManifestStore().recordSurfaceState(
      surface: 'feed',
      userId: userId,
      itemCount: count,
      hasLocalSnapshot: count > 0,
      source: count > 0 ? source : 'none',
      startupShardHydrated: startupShardHydrated,
      startupShardAgeMs: startupShardAgeMs,
    );
  }

  Future<void> _persistFeedStartupShardOnly({
    required String userId,
    required List<PostsModel> ordered,
    required DateTime snapshotAt,
    required String source,
  }) async {
    final limit = FeedSnapshotRepository.startupHomeLimit;
    if (ordered.isEmpty) {
      await ensureStartupSnapshotShardStore().clear(
        surface: 'feed',
        userId: userId,
      );
      await _recordFeedStartupSurface(
        source: 'none',
        itemCount: 0,
      );
      return;
    }
    await ensureStartupSnapshotShardStore().save(
      surface: 'feed',
      userId: userId,
      itemCount: ordered.length,
      limit: limit,
      source: source,
      snapshotAt: snapshotAt,
      payload: _feedSnapshotRepository.encodeHomeStartupPayload(
        ordered,
        limit: limit,
      ),
    );
    await _recordFeedStartupSurface(
      source: source,
      itemCount: ordered.length,
    );
  }
}
