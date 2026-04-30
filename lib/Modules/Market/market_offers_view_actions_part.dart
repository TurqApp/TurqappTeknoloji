part of 'market_offers_view.dart';

extension _MarketOffersViewActionsPart on _MarketOffersViewState {
  Future<void> _respondToOffer({
    required MarketOfferModel offer,
    required String status,
  }) async {
    _updateViewState(() {
      _processingIds.add(offer.id);
    });
    try {
      await MarketOfferService.respondToOffer(offer: offer, status: status);
      if (!mounted) return;
      _updateViewState(() {
        _processingIds.remove(offer.id);
        _reload();
      });
      AppSnackbar(
        'common.info'.tr,
        status == kMarketOfferStatusAccepted
            ? 'pasaj.market.offer_accepted'.tr
            : 'pasaj.market.offer_rejected'.tr,
      );
    } catch (e) {
      if (!mounted) return;
      _updateViewState(() {
        _processingIds.remove(offer.id);
      });
      final text = e.toString().contains('offer_already_processed')
          ? 'pasaj.market.offer_already_processed'.tr
          : 'pasaj.market.offer_update_failed'.tr;
      AppSnackbar('common.error'.tr, text);
    }
  }

  Future<void> _openOfferItem(MarketOfferModel offer) async {
    final item = await _repository.fetchById(
      offer.itemId,
      forceRefresh: true,
    );
    if (item == null) {
      AppSnackbar('common.error'.tr, 'pasaj.market.listing_unavailable'.tr);
      return;
    }
    await const MarketDetailNavigationService().openMarketDetail(item);
  }
}
