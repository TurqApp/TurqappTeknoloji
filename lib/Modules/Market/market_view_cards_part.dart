part of 'market_view.dart';

extension _MarketViewCardsPart on MarketView {
  Widget _buildGridSavedOverlay(MarketItemModel item) {
    return Obx(
      () => GestureDetector(
        onTap: () => controller.toggleSaved(item, showSnackbar: false),
        child: SizedBox(
          width: PasajListCardMetrics.gridOverlayButtonSize,
          height: PasajListCardMetrics.gridOverlayButtonSize,
          child: Center(
            child: Icon(
              controller.isSaved(item.id) ? AppIcons.saved : AppIcons.save,
              color: Colors.white,
              size: PasajListCardMetrics.gridOverlayIconSize,
              shadows: const [
                Shadow(
                  color: Color(0x55000000),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListingCard(MarketItemModel item) {
    return Obx(
      () => MarketListingCard(
        item: item,
        isSaved: controller.isSaved(item.id),
        onOpen: () => controller.openItem(item),
        onToggleSaved: () => controller.toggleSaved(
          item,
          showSnackbar: false,
        ),
      ),
    );
  }

  Widget _buildGridCard(MarketItemModel item) {
    final accent = _accentForItem(item);
    final statusColor = _statusColor(item.status);
    final canCall = item.canShowPhone;
    return PasajGridCard(
      key: ValueKey(IntegrationTestKeys.marketItem(item.id)),
      onTap: () => controller.openItem(item),
      media: _MarketGridMedia(
        item: item,
        accent: accent,
        radius: PasajListCardMetrics.gridRadius,
        fallbackBuilder: (marketItem, marketAccent) =>
            _buildItemFallback(marketItem, marketAccent),
      ),
      overlay: _buildGridSavedOverlay(item),
      lines: [
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.lineOne,
        ),
        Text(
          item.status == 'active'
              ? item.categoryLabel
              : _statusLabel(item.status),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.gridLineTwo(
            item.status == 'active' ? accent : statusColor,
          ),
        ),
        Text(
          item.description.trim(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: PasajCardStyles.detail,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                item.locationText.isNotEmpty ? item.locationText : item.city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: PasajCardStyles.gridLineFour(
                  PasajCardStyles.lineFourColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                item.price > 0
                    ? '${_formattedPrice(item.price)} ${_currencyLabel(item.currency)}'
                    : '',
                maxLines: 1,
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: PasajCardStyles.gridPrice,
              ),
            ),
          ],
        ),
      ],
      cta: Container(
        height: PasajListCardMetrics.gridCtaHeight,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: canCall ? Colors.green : Colors.black,
          borderRadius: const BorderRadius.all(
            Radius.circular(PasajListCardMetrics.gridCtaRadius),
          ),
        ),
        child: InkWell(
          onTap: () {
            if (canCall) {
              MarketView._contactService.callPhone(item);
            } else {
              controller.openItem(item);
            }
          },
          child: Center(
            child: Text(
              canCall ? 'pasaj.market.call_now'.tr : 'pasaj.market.inspect'.tr,
              style: PasajCardStyles.gridCta,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemFallback(MarketItemModel item, Color accent) {
    return Center(
      child: Icon(
        _marketItemIcon(item),
        color: accent,
        size: 30,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront_outlined, size: 42, color: Colors.black38),
            SizedBox(height: 10),
            Text(
              'pasaj.market.empty_filtered'.tr,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontFamily: 'MontserratBold',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
