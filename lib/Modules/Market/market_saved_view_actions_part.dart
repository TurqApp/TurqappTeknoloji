part of 'market_saved_view.dart';

extension MarketSavedViewActionsPart on _MarketSavedViewState {
  Widget _buildItemCard(MarketItemModel item) {
    return MarketListingCard(
      item: item,
      isSaved: true,
      onOpen: () async {
        await const MarketDetailNavigationService().openMarketDetail(item);
        if (!mounted) return;
        _updateViewState(() => _reload(force: true));
      },
      onToggleSaved: () => _unsave(item),
    );
  }

  Future<void> _unsave(MarketItemModel item) async {
    try {
      final uid = await _resolveCurrentUid();
      if (uid.isEmpty) {
        AppSnackbar(
          'pasaj.market.sign_in_required_title'.tr,
          'pasaj.market.sign_in_to_save'.tr,
        );
        return;
      }
      await MarketSavedStore.unsave(uid, item.id);
      if (!mounted) return;
      _updateViewState(() {
        _reload(force: true);
      });
    } catch (_) {
      AppSnackbar('common.error'.tr, 'pasaj.market.unsave_failed'.tr);
    }
  }
}
