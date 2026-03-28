part of 'market_controller.dart';

extension _MarketControllerHomePart on MarketController {
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
      final allowRefresh = allowBackgroundRefresh ?? false;
      await _performHydrateMarketStartupShard();
      await _performRestoreListingSelection();

      try {
        await _schemaService.loadSchema();
        final loadedCategories = _schemaService
            .categories()
            .where(_isVisibleCategory)
            .toList(growable: true)
          ..sort(
            (a, b) => _compareCategoryPriority(
              (a['label'] ?? '').toString(),
              (b['label'] ?? '').toString(),
            ),
          );
        final roundMenu = _schemaService.roundMenuItems();
        if (!_sameMapList(categories, loadedCategories)) {
          categories.assignAll(loadedCategories);
        }
        if (!_sameMapList(roundMenuItems, roundMenu)) {
          roundMenuItems.assignAll(roundMenu);
        }
      } catch (_) {}

      await _loadSavedItems();
      final userId = CurrentUserService.instance.effectiveUserId;
      _homeSnapshotSub ??= _marketSnapshotRepository
          .openHome(
        userId: userId,
        limit: ReadBudgetRegistry.marketHomeInitialLimit,
      )
          .listen((resource) {
        unawaited(_applyHomeSnapshotResource(resource));
      });

      if (items.isEmpty && visibleItems.isEmpty) {
        await _loadListingFromSnapshot(forceRefresh: false);
        _applyFilters();
      }

      if (allowRefresh) {
        unawaited(loadHomeData(silent: true));
      } else if (visibleItems.isEmpty && items.isNotEmpty) {
        _applyFilters();
      }
    } finally {
      unawaited(_persistMarketStartupShard());
      unawaited(_recordMarketStartupSurface());
    }
  }

  Future<void> _performHydrateMarketStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    _startupShardHydrated = false;
    _startupShardAgeMs = null;
    try {
      final shard = await ensureStartupSnapshotShardStore().load(
        surface: 'market',
        userId: userId,
        maxAge: StartupSnapshotShardStore.defaultFreshWindow,
      );
      if (shard == null) return;
      var didHydrate = false;
      final rawSelection = (shard.payload['listingSelection'] as num?)?.toInt();
      if (rawSelection != null) {
        listingSelection.value = rawSelection == 1 ? 1 : 0;
        listingSelectionReady.value = true;
        didHydrate = true;
      }
      final decoded = _decodeMarketStartupItems(shard.payload['items']);
      if (decoded.isEmpty) return;
      if (items.isEmpty) {
        items.assignAll(decoded);
        didHydrate = true;
      }
      if (visibleItems.isEmpty) {
        visibleItems.assignAll(decoded);
        didHydrate = true;
      }
      if (!didHydrate) return;
      _startupShardHydrated = true;
      _startupShardAgeMs =
          DateTime.now().millisecondsSinceEpoch - shard.savedAtMs;
    } catch (_) {}
  }

  Future<void> _persistMarketStartupShard() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final sourceItems = visibleItems.isNotEmpty ? visibleItems : items;
    final startupItems = sourceItems.take(8).toList(growable: false);
    final store = ensureStartupSnapshotShardStore();
    if (startupItems.isEmpty) {
      await store.clear(
        surface: 'market',
        userId: userId,
      );
      return;
    }
    await store.save(
      surface: 'market',
      userId: userId,
      itemCount: sourceItems.length,
      limit: 8,
      source: 'market_snapshot',
      payload: <String, dynamic>{
        'listingSelection': listingSelection.value == 1 ? 1 : 0,
        'items':
            startupItems.map((item) => item.toJson()).toList(growable: false),
      },
    );
  }

  Future<void> _recordMarketStartupSurface() async {
    final userId = CurrentUserService.instance.effectiveUserId.trim();
    if (userId.isEmpty) return;
    final visibleCount = visibleItems.length;
    final itemCount = visibleCount > 0 ? visibleCount : items.length;
    final hasLocalSnapshot = itemCount > 0;
    try {
      await ensureStartupSnapshotManifestStore().recordSurfaceState(
        surface: 'market',
        userId: userId,
        itemCount: itemCount,
        hasLocalSnapshot: hasLocalSnapshot,
        source: hasLocalSnapshot ? 'market_snapshot' : 'none',
        startupShardHydrated: _startupShardHydrated,
        startupShardAgeMs: _startupShardAgeMs,
      );
    } catch (_) {}
  }

  List<MarketItemModel> _decodeMarketStartupItems(dynamic raw) {
    if (raw is! List) return const <MarketItemModel>[];
    return raw
        .whereType<Map>()
        .map((entry) {
          try {
            return MarketItemModel.fromJson(
              Map<String, dynamic>.from(entry.cast<dynamic, dynamic>()),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<MarketItemModel>()
        .toList(growable: false);
  }

  Future<void> _performRestoreListingSelection() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      listingSelection.value = 1;
      listingSelectionReady.value = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_listingSelectionKeyFor(uid));
      listingSelection.value = stored == null ? 1 : (stored == 1 ? 1 : 0);
    } catch (_) {
      listingSelection.value = 1;
    } finally {
      listingSelectionReady.value = true;
    }
  }

  Future<void> _performPersistListingSelection() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        _listingSelectionKeyFor(uid),
        listingSelection.value == 1 ? 1 : 0,
      );
    } catch (_) {}
  }

  Future<void> _performBootstrapHomeData() async {
    try {
      await _schemaService.loadSchema();
      final loadedCategories = _schemaService
          .categories()
          .where(_isVisibleCategory)
          .toList(growable: true)
        ..sort(
          (a, b) => _compareCategoryPriority(
            (a['label'] ?? '').toString(),
            (b['label'] ?? '').toString(),
          ),
        );
      final roundMenu = _schemaService.roundMenuItems();
      if (!_sameMapList(categories, loadedCategories)) {
        categories.assignAll(loadedCategories);
      }
      if (!_sameMapList(roundMenuItems, roundMenu)) {
        roundMenuItems.assignAll(roundMenu);
      }
    } catch (_) {}
    await _loadSavedItems();
    final userId = CurrentUserService.instance.effectiveUserId;
    _homeSnapshotSub?.cancel();
    _homeSnapshotSub = _marketSnapshotRepository
        .openHome(
      userId: userId,
      limit: ReadBudgetRegistry.marketHomeInitialLimit,
    )
        .listen((resource) {
      unawaited(_applyHomeSnapshotResource(resource));
    });
  }

  Future<void> _performLoadHomeData({
    required bool forceRefresh,
    required bool silent,
  }) async {
    final shouldShowLoader = !silent && items.isEmpty && visibleItems.isEmpty;
    if (shouldShowLoader) {
      isLoading.value = true;
    }
    try {
      await _schemaService.loadSchema();
      final loadedCategories = _schemaService
          .categories()
          .where(_isVisibleCategory)
          .toList(growable: true)
        ..sort(
          (a, b) => _compareCategoryPriority(
            (a['label'] ?? '').toString(),
            (b['label'] ?? '').toString(),
          ),
        );
      final roundMenu = _schemaService.roundMenuItems();
      if (!_sameMapList(categories, loadedCategories)) {
        categories.assignAll(loadedCategories);
      }
      if (!_sameMapList(roundMenuItems, roundMenu)) {
        roundMenuItems.assignAll(roundMenu);
      }
      await _loadListingFromSnapshot(forceRefresh: forceRefresh);
      await _loadAllCityOptions();
      await _loadSavedItems();
      await _loadRoundMenuBadges(forceRefresh: forceRefresh);
      _applyFilters();
    } finally {
      if (shouldShowLoader) {
        isLoading.value = false;
      }
    }
  }

  void _performToggleListingSelection() {
    listingSelection.value = listingSelection.value == 0 ? 1 : 0;
    unawaited(_persistListingSelection());
  }

  Future<void> _performRefreshHome() async {
    await loadHomeData(forceRefresh: true);
  }

  Future<void> _performLoadListingFromSnapshot({
    required bool forceRefresh,
  }) async {
    try {
      final fetched = await _marketSnapshotRepository.loadHome(
        userId: CurrentUserService.instance.effectiveUserId,
        limit: ReadBudgetRegistry.marketHomeInitialLimit,
        forceSync: forceRefresh,
      );
      final activeFetched = (fetched.data ?? const <MarketItemModel>[])
          .where((item) => item.status == 'active')
          .toList(growable: false);
      final merged = _mergePendingCreatedItems(activeFetched);
      if (!_sameMarketList(merged)) {
        items.assignAll(merged);
      }
    } catch (_) {
      final merged = _mergePendingCreatedItems(const <MarketItemModel>[]);
      if (!_sameMarketList(merged)) {
        items.assignAll(merged);
      }
    }
  }

  Future<void> _performReloadListingForCurrentFilters() async {
    isSearchLoading.value = true;
    try {
      await _loadListingFromSnapshot();
      await _loadAllCityOptions();
      _applyFilters();
    } finally {
      isSearchLoading.value = false;
    }
  }

  Future<void> _performApplyHomeSnapshotResource(
    CachedResource<List<MarketItemModel>> resource,
  ) async {
    final activeItems = (resource.data ?? const <MarketItemModel>[])
        .where((item) => item.status == 'active')
        .toList(growable: false);
    if (activeItems.isNotEmpty) {
      final nextItems = _mergePendingCreatedItems(activeItems);
      if (!_sameMarketList(nextItems)) {
        items.assignAll(nextItems);
        _applyFilters();
      }
      unawaited(_loadAllCityOptions());
      unawaited(_loadSavedItems());
      unawaited(_loadRoundMenuBadges(forceRefresh: false));
    }

    if (!resource.isRefreshing || activeItems.isNotEmpty) {
      isLoading.value = false;
      return;
    }
    if (items.isEmpty && visibleItems.isEmpty) {
      isLoading.value = true;
    }
  }
}
