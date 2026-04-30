part of 'job_finder_controller.dart';

extension JobFinderControllerLifecyclePart on JobFinderController {
  void _handleOnInit() {
    unawaited(_performPrepareStartupSurface());
    search.addListener(_searchListener);
  }

  void _handleOnClose() {
    _homeSnapshotSub?.cancel();
    _deferredLocationTimer?.cancel();
    innerPageController.dispose();
    search.dispose();
  }

  Future<void> _restoreListingSelection() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) {
      listingSelection.value = 1;
      listingSelectionReady.value = true;
      return;
    }
    try {
      final stored = await _localPreferenceRepository.getInt(
        _listingSelectionKeyFor(uid),
      );
      listingSelection.value = stored == null ? 1 : (stored == 1 ? 1 : 0);
    } catch (_) {
      listingSelection.value = 1;
    } finally {
      listingSelectionReady.value = true;
    }
  }

  Future<void> _persistListingSelection() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      await _localPreferenceRepository.setInt(
        _listingSelectionKeyFor(uid),
        listingSelection.value == 1 ? 1 : 0,
      );
    } catch (_) {}
  }

  void _searchListener() {
    final query = search.text.trim();
    if (query.length >= 2) {
      searchFromTypesense(query);
    } else {
      _searchRequestId++;
      aramaSonucu.clear();
    }
  }
}
