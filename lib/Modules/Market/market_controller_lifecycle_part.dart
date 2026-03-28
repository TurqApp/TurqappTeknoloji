part of 'market_controller.dart';

extension _MarketControllerLifecyclePart on MarketController {
  void _handleLifecycleInit() {
    unawaited(_restoreListingSelection());
    scrollController.addListener(_onScroll);
    unawaited(_loadRecentSearches());
    unawaited(prepareStartupSurface());
  }

  void _handleLifecycleClose() {
    _homeSnapshotSub?.cancel();
    _searchDebounce?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    search.dispose();
  }

  void _performOnScroll() {
    if (!scrollController.hasClients) return;
    scrollOffset.value = scrollController.offset;
  }

  String _listingSelectionKeyFor(String uid) =>
      '${_marketListingSelectionPrefKeyPrefix}_$uid';
}
