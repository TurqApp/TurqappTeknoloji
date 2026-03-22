part of 'market_controller.dart';

extension _MarketControllerHomePart on MarketController {
  Future<void> _performRestoreListingSelection() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      listingSelection.value = 0;
      listingSelectionReady.value = true;
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt(_listingSelectionKeyFor(uid));
      listingSelection.value = stored == 1 ? 1 : 0;
    } catch (_) {
      listingSelection.value = 0;
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
        .openHome(userId: userId, limit: 120)
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

  Future<void> _performOpenItem(MarketItemModel item) async {
    await Get.to(() => MarketDetailView(item: item));
    await loadHomeData(forceRefresh: true);
  }

  Future<void> _performToggleSaved(
    MarketItemModel item, {
    required bool showSnackbar,
  }) async {
    if (!UserModerationGuard.ensureAllowed(RestrictedAction.saveMarket)) {
      return;
    }
    final uid = _currentUid;
    if (uid.isEmpty) {
      AppSnackbar(
        'pasaj.market.sign_in_required_title'.tr,
        'pasaj.market.sign_in_to_save'.tr,
      );
      return;
    }
    final currentlySaved = isSaved(item.id);
    if (currentlySaved) {
      savedItemIds.remove(item.id);
      _applyLocalFavoriteDelta(item.id, -1);
    } else {
      savedItemIds.add(item.id);
      _applyLocalFavoriteDelta(item.id, 1);
    }
    try {
      if (currentlySaved) {
        await MarketSavedStore.unsave(uid, item.id);
      } else {
        await MarketSavedStore.save(uid, item.id);
      }
      if (showSnackbar) {
        AppSnackbar(
          'common.success'.tr,
          currentlySaved
              ? 'pasaj.market.unsaved'.tr
              : 'pasaj.market.saved_success'.tr,
        );
      }
    } catch (_) {
      if (currentlySaved) {
        savedItemIds.add(item.id);
        _applyLocalFavoriteDelta(item.id, 1);
      } else {
        savedItemIds.remove(item.id);
        _applyLocalFavoriteDelta(item.id, -1);
      }
      if (showSnackbar) {
        AppSnackbar(
          'common.error'.tr,
          'pasaj.market.save_failed'.tr,
        );
      }
    }
  }

  Future<void> _performOpenRoundMenu(String key) async {
    switch (key) {
      case 'create':
        final result = await Get.to(() => const MarketCreateView());
        if (result != null) {
          if (result is Map) {
            final item = MarketItemModel.fromJson(
              Map<String, dynamic>.from(result),
            );
            _upsertVisibleItem(item);
            _applyFilters();
            Future.delayed(const Duration(seconds: 2), () {
              unawaited(loadHomeData(forceRefresh: true));
            });
          } else {
            await loadHomeData(forceRefresh: true);
          }
        }
        return;
      case 'my_items':
        await Get.to(() => const MarketMyItemsView());
        await loadHomeData(forceRefresh: true);
        return;
      case 'saved':
        await Get.to(() => const MarketSavedView());
        await loadHomeData(forceRefresh: true);
        return;
      case 'offers':
        await Get.to(() => const MarketOffersView());
        await loadHomeData(forceRefresh: true);
        return;
      case 'categories':
        Get.bottomSheet(
          MarketCategorySheet(controller: this),
          backgroundColor: Colors.white,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        );
        return;
      case 'nearby':
        unawaited(focusNearbyItems());
        return;
      default:
        showComingSoon(key.isEmpty ? 'Market' : key);
    }
  }

  void _performShowComingSoon(String title) {
    AppSnackbar(
      'pasaj.market.coming_soon_title'.tr,
      'pasaj.market.coming_soon_body'.trParams({'title': title}),
    );
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
        limit: 120,
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

  Future<void> _performLoadSavedItems() async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      if (savedItemIds.isNotEmpty) {
        savedItemIds.clear();
      }
      return;
    }
    try {
      final ids = (await MarketSavedStore.getSavedItemIds(uid)).toList(
        growable: false,
      )..sort();
      if (_sameStringList(savedItemIds, ids)) {
        return;
      }
      savedItemIds.assignAll(ids);
    } catch (_) {
      if (savedItemIds.isNotEmpty) {
        savedItemIds.clear();
      }
    }
  }

  Future<void> _performLoadRoundMenuBadges({
    required bool forceRefresh,
  }) async {
    final uid = _currentUid;
    if (uid.isEmpty) {
      if (roundMenuBadges.isNotEmpty) {
        roundMenuBadges.assignAll(const <String, int>{});
      }
      return;
    }

    try {
      final ownerFuture = _repository.fetchByOwner(
        uid,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      final sentFuture = MarketOfferService.fetchSentOffers(uid);
      final receivedFuture = MarketOfferService.fetchReceivedOffers(uid);
      final results = await Future.wait<dynamic>([
        ownerFuture,
        sentFuture,
        receivedFuture,
      ]);

      final ownerItems = (results[0] as List<MarketItemModel>)
          .where((item) => item.status != 'archived')
          .length;
      final sentOffers = results[1] as List<MarketOfferModel>;
      final receivedOffers = results[2] as List<MarketOfferModel>;
      final totalOffers = sentOffers.length + receivedOffers.length;

      final next = <String, int>{
        'my_items': ownerItems,
        'saved': savedItemIds.length,
        'offers': totalOffers,
      };
      if (_sameBadgeMap(roundMenuBadges, next)) {
        return;
      }
      roundMenuBadges.assignAll(next);
    } catch (_) {
      final fallback = <String, int>{
        'my_items': roundMenuBadges['my_items'] ?? 0,
        'saved': savedItemIds.length,
        'offers': roundMenuBadges['offers'] ?? 0,
      };
      if (_sameBadgeMap(roundMenuBadges, fallback)) {
        return;
      }
      roundMenuBadges.assignAll(fallback);
    }
  }

  void _performApplyLocalFavoriteDelta(String itemId, int delta) {
    if (delta == 0) return;
    items.assignAll(_updateFavoriteCount(items, itemId, delta));
    searchedItems.assignAll(_updateFavoriteCount(searchedItems, itemId, delta));
    _applyFilters();
  }

  List<MarketItemModel> _performUpdateFavoriteCount(
    List<MarketItemModel> source,
    String itemId,
    int delta,
  ) {
    return source.map((item) {
      if (item.id != itemId) return item;
      final nextCount = item.favoriteCount + delta;
      return item.copyWith(
        favoriteCount: nextCount < 0 ? 0 : nextCount,
      );
    }).toList(growable: false);
  }

  void _performUpsertVisibleItem(MarketItemModel item) {
    if (item.status != 'active') return;
    final next = <MarketItemModel>[item];
    next.addAll(items.where((existing) => existing.id != item.id));
    items.assignAll(next);
    pendingCreatedItems.removeWhere((existing) => existing.id == item.id);
    pendingCreatedItems.insert(0, item);
  }

  List<MarketItemModel> _performMergePendingCreatedItems(
    List<MarketItemModel> source,
  ) {
    if (pendingCreatedItems.isEmpty) return source;
    final merged = <MarketItemModel>[];
    final seenIds = <String>{};
    final syncedIds = <String>{};
    final pendingById = <String, MarketItemModel>{
      for (final pending in pendingCreatedItems) pending.id: pending,
    };

    for (final item in source) {
      final pending = pendingById[item.id];
      if (pending != null && pending.status == 'active') {
        final protected = _preserveProtectedFields(item, pending);
        merged.add(protected);
        if (_isSyncedWithPending(protected, pending)) {
          syncedIds.add(item.id);
        }
      } else {
        merged.add(item);
      }
      seenIds.add(item.id);
    }

    for (final pending in pendingCreatedItems) {
      if (pending.status != 'active') continue;
      if (!seenIds.add(pending.id)) continue;
      merged.insert(0, pending);
    }

    pendingCreatedItems
        .removeWhere((pending) => syncedIds.contains(pending.id));
    return merged;
  }

  MarketItemModel _performPreserveProtectedFields(
    MarketItemModel remote,
    MarketItemModel local,
  ) {
    final shouldKeepPhone = !remote.canShowPhone &&
        local.canShowPhone &&
        local.sellerPhoneNumber.trim().isNotEmpty;

    if (!shouldKeepPhone) return remote;

    return remote.copyWith(
      showPhone: true,
      contactPreference: 'phone',
      sellerPhoneNumber: local.sellerPhoneNumber,
    );
  }

  bool _performIsSyncedWithPending(
    MarketItemModel remote,
    MarketItemModel local,
  ) {
    if (local.canShowPhone &&
        local.sellerPhoneNumber.trim().isNotEmpty &&
        (!remote.canShowPhone ||
            remote.sellerPhoneNumber.trim() !=
                local.sellerPhoneNumber.trim())) {
      return false;
    }
    return true;
  }
}
