part of 'market_view.dart';

extension _MarketViewCardsPart on MarketView {
  Widget _buildSavedActionButton(
    MarketItemModel item, {
    required double buttonSize,
    required double iconSize,
  }) {
    return Obx(
      () => AppHeaderActionButton(
        onTap: () => controller.toggleSaved(
          item,
          showSnackbar: false,
        ),
        size: buttonSize,
        child: Icon(
          controller.isSaved(item.id) ? AppIcons.saved : AppIcons.save,
          color: controller.isSaved(item.id)
              ? Colors.orange
              : Colors.grey.shade600,
          size: iconSize,
        ),
      ),
    );
  }

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
    final accent = _accentForItem(item);
    final canCall = item.canShowPhone;
    return GestureDetector(
      key: ValueKey(IntegrationTestKeys.marketItem(item.id)),
      onTap: () => controller.openItem(item),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
            color: Colors.white,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final metrics = PasajListCardMetrics.forWidth(
                constraints.maxWidth,
              );
              final buttonText = canCall
                  ? 'pasaj.market.call_now'.tr
                  : 'pasaj.market.inspect'.tr;

              Widget actionButtons() {
                final children = [
                  AppHeaderActionButton(
                    onTap: () => const MarketShareService().shareItem(item),
                    size: metrics.actionButtonSize,
                    child: Icon(
                      AppIcons.share,
                      color: Colors.black.withValues(alpha: 0.85),
                      size: metrics.actionIconSize,
                    ),
                  ),
                  SizedBox(width: compact ? 0 : 6, height: compact ? 6 : 0),
                  _buildSavedActionButton(
                    item,
                    buttonSize: metrics.actionButtonSize,
                    iconSize: metrics.actionIconSize,
                  ),
                ];

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    children[0],
                    const SizedBox(width: 6),
                    children[2],
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemVisual(
                    item,
                    accent,
                    width: metrics.mediaSize,
                    height: metrics.mediaSize,
                    radius: 10,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: metrics.railHeight,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: metrics.detailRowHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PasajCardStyles.lineOne,
                              ),
                            ),
                          ),
                          SizedBox(height: metrics.contentGap),
                          SizedBox(
                            height: metrics.detailRowHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.status == 'active'
                                    ? item.categoryLabel
                                    : _statusLabel(item.status),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PasajCardStyles.lineTwo,
                              ),
                            ),
                          ),
                          SizedBox(height: metrics.contentGap),
                          SizedBox(
                            height: metrics.detailRowHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: item.description.trim().isNotEmpty
                                  ? Text(
                                      item.description.trim(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: PasajCardStyles.detail,
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          SizedBox(height: metrics.contentGap),
                          SizedBox(
                            height: metrics.ctaHeight,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item.locationText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: PasajCardStyles.lineFour,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: metrics.railWidth,
                    height: metrics.railHeight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        actionButtons(),
                        SizedBox(height: metrics.railSectionGap),
                        SizedBox(
                          height: metrics.middleSlotHeight,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_formattedPrice(item.price)} ${_currencyLabel(item.currency)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF8B0000),
                                fontSize: compact ? 16 : 17,
                                fontFamily: 'MontserratBold',
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            if (canCall) {
                              MarketView._contactService.callPhone(item);
                            } else {
                              controller.openItem(item);
                            }
                          },
                          child: Container(
                            constraints: BoxConstraints(
                              minWidth: metrics.railWidth,
                            ),
                            height: metrics.ctaHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 14 : 16,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: canCall ? Colors.green : Colors.black,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: Text(
                              buttonText,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: metrics.ctaFontSize,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
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

  Widget _buildItemVisual(
    MarketItemModel item,
    Color accent, {
    double? width,
    double? height,
    required double radius,
  }) {
    final child = item.coverImageUrl.isNotEmpty
        ? Image.network(
            item.coverImageUrl,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => _buildItemFallback(item, accent),
          )
        : _buildItemFallback(item, accent);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: accent.withValues(alpha: 0.12),
        child: child,
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
