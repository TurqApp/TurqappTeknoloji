part of 'tutoring_controller.dart';

extension TutoringControllerDataPart on TutoringController {
  void _performHydrateTutoringStartupSeedPoolSync() {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    try {
      final shard = ensureStartupSnapshotSeedPool().load(
        surface: 'tutoring',
        userId: userId,
      );
      if (shard == null) return;
      final decoded = _decodeTutoringStartupItems(shard.payload['items']);
      if (decoded.isNotEmpty && tutoringList.isEmpty) {
        tutoringList.assignAll(decoded);
      }
    } catch (_) {}
  }

  Future<void> _performHydrateTutoringStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    try {
      final shard = await ensureStartupSnapshotShardStore().load(
        surface: 'tutoring',
        userId: userId,
        maxAge: StartupSnapshotShardStore.defaultFreshWindow,
      );
      if (shard == null) return;
      final decoded = _decodeTutoringStartupItems(shard.payload['items']);
      if (decoded.isNotEmpty && tutoringList.isEmpty) {
        tutoringList.assignAll(decoded);
      }
    } catch (_) {}
  }

  List<TutoringModel> _decodeTutoringStartupItems(dynamic raw) {
    if (raw is! List) return const <TutoringModel>[];
    return raw
        .whereType<Map>()
        .map((entry) {
          final map = Map<String, dynamic>.from(entry.cast<dynamic, dynamic>());
          final docId = (map['docID'] ?? '').toString().trim();
          final data = map['data'];
          if (docId.isEmpty || data is! Map) return null;
          try {
            return TutoringModel.fromJson(
              Map<String, dynamic>.from(data.cast<dynamic, dynamic>()),
              docId,
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<TutoringModel>()
        .toList(growable: false);
  }

  Future<void> _persistTutoringStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final startupLimit = ReadBudgetRegistry.startupListingWarmLimit(
      onWiFi: true,
    );
    final startupItems = tutoringList
        .take(startupLimit)
        .toList(growable: false);
    final store = ensureStartupSnapshotShardStore();
    if (startupItems.isEmpty) {
      await store.clear(surface: 'tutoring', userId: userId);
      return;
    }
    await store.save(
      surface: 'tutoring',
      userId: userId,
      itemCount: tutoringList.length,
      limit: startupLimit,
      source: 'tutoring_snapshot',
      payload: <String, dynamic>{
        'items': startupItems
            .map(
              (item) => <String, dynamic>{
                'docID': item.docID,
                'data': item.toJson(),
              },
            )
            .toList(growable: false),
      },
    );
  }

  // Kept for staged rollout; real-time bootstrap is wired by follow-up controller refactor.
  // ignore: unused_element
  Future<void> _bootstrapTutoringData() async {
    final savedController = ensureSavedTutoringsController(permanent: true);
    await savedController.loadSavedTutorings();
    final userId = CurrentUserService.instance.effectiveUserId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _tutoringSnapshotRepository
        .openHome(
          userId: userId,
          limit: TutoringController._pageSize,
        )
        .listen(_applyHomeSnapshotResource);
  }

  void _onScroll() {
    scrollOffset.value = scrollController.offset;
    if (scrollController.position.pixels >=
            scrollController.position.maxScrollExtent - 200 &&
        !hasActiveSearch &&
        !isLoadingMore.value &&
        hasMore.value) {
      loadMore();
    }
  }

  Future<void> listenToTutoringData({
    bool forceRefresh = false,
  }) async {
    final hadLocalItems = tutoringList.isNotEmpty;
    if (!hadLocalItems) {
      isLoading.value = true;
    }
    hasMore.value = true;
    _currentPage = 1;
    try {
      final result = await _tutoringSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: TutoringController._pageSize,
        forceSync: forceRefresh,
      );
      final items = result.data ?? const <TutoringModel>[];
      hasMore.value = items.length >= TutoringController._pageSize;
      final nextList = _applyPersonalization(items);
      if (!_sameTutoringList(this, nextList)) {
        tutoringList.assignAll(nextList);
      }
      unawaited(_persistTutoringStartupShard());
      SilentRefreshGate.markRefreshed('tutoring:home');
    } catch (_) {
      if (tutoringList.isNotEmpty) {
        tutoringList.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMore.value) return;

    isLoadingMore.value = true;
    try {
      final nextPage = _currentPage + 1;
      final result = await _tutoringSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: TutoringController._pageSize,
        page: nextPage,
        forceSync: true,
      );
      final newItems = result.data ?? const <TutoringModel>[];
      hasMore.value = newItems.length >= TutoringController._pageSize;
      _currentPage = nextPage;

      final existingIds = tutoringList.map((item) => item.docID).toSet();
      final merged =
          newItems.where((item) => !existingIds.contains(item.docID));
      tutoringList.addAll(merged);
    } catch (_) {
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _applyHomeSnapshotResource(
    CachedResource<List<TutoringModel>> resource,
  ) async {
    final items = resource.data ?? const <TutoringModel>[];
    if (items.isNotEmpty) {
      hasMore.value = items.length >= TutoringController._pageSize;
      final nextList = _applyPersonalization(items);
      if (!_sameTutoringList(this, nextList)) {
        tutoringList.assignAll(nextList);
      }
      unawaited(_persistTutoringStartupShard());
    }

    if (!resource.isRefreshing || items.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (tutoringList.isEmpty) {
      isLoading.value = true;
    }
  }
}
