import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/market_contact_service.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';
import 'package:turqappv2/Themes/app_icons.dart';

class MarketListingCard extends StatelessWidget {
  const MarketListingCard({
    super.key,
    required this.item,
    required this.isSaved,
    required this.onOpen,
    required this.onToggleSaved,
  });

  static const MarketContactService _contactService = MarketContactService();

  final MarketItemModel item;
  final bool isSaved;
  final Future<void> Function() onOpen;
  final Future<void> Function() onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForItem(item);
    final canCall = item.canShowPhone;

    return GestureDetector(
      key: ValueKey(IntegrationTestKeys.marketItem(item.id)),
      onTap: () async => onOpen(),
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppHeaderActionButton(
                              onTap: () => const MarketShareService().shareItem(
                                item,
                              ),
                              size: metrics.actionButtonSize,
                              child: Icon(
                                AppIcons.share,
                                color: Colors.black.withValues(alpha: 0.85),
                                size: metrics.actionIconSize,
                              ),
                            ),
                            const SizedBox(width: 6),
                            AppHeaderActionButton(
                              onTap: () async => onToggleSaved(),
                              size: metrics.actionButtonSize,
                              child: Icon(
                                isSaved ? AppIcons.saved : AppIcons.save,
                                color: isSaved
                                    ? Colors.orange
                                    : Colors.grey.shade600,
                                size: metrics.actionIconSize,
                              ),
                            ),
                          ],
                        ),
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
                          onTap: () async {
                            if (canCall) {
                              await _contactService.callPhone(item);
                              return;
                            }
                            await onOpen();
                          },
                          child: Container(
                            constraints: BoxConstraints(
                              minWidth: metrics.railWidth,
                            ),
                            height: metrics.ctaHeight,
                            padding: EdgeInsets.symmetric(
                              horizontal: compact ? 10 : 12,
                            ),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: canCall ? Colors.green : Colors.black,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                buttonText,
                                maxLines: 1,
                                softWrap: false,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: metrics.ctaFontSize,
                                  fontFamily: 'MontserratMedium',
                                ),
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

  Color _accentForItem(MarketItemModel item) {
    final lower = normalizeSearchText(item.categoryKey);
    if (lower.contains('elektronik') || lower.contains('telefon')) {
      return const Color(0xFF2563EB);
    }
    if (lower.contains('ev-yasam') || lower.contains('mobilya')) {
      return const Color(0xFFEA580C);
    }
    if (lower.contains('spor')) {
      return const Color(0xFF16A34A);
    }
    return const Color(0xFF111827);
  }

  String _currencyLabel(String value) {
    return marketCurrencyLabel(value);
  }

  String _formattedPrice(double value) {
    final digits = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sold':
        return 'pasaj.market.status.sold'.tr;
      case 'reserved':
        return 'pasaj.market.status.reserved'.tr;
      case 'draft':
        return 'pasaj.market.status.draft'.tr;
      case 'archived':
        return 'pasaj.market.status.archived'.tr;
      default:
        return 'pasaj.market.status.active'.tr;
    }
  }

  IconData _marketItemIcon(MarketItemModel item) {
    final lower = normalizeSearchText(
      '${item.categoryKey} ${item.categoryLabel}',
    );
    if (lower.contains('telefon') || lower.contains('iphone')) {
      return Icons.phone_iphone_rounded;
    }
    if (lower.contains('bilgisayar') || lower.contains('laptop')) {
      return Icons.laptop_mac_rounded;
    }
    if (lower.contains('koltuk') || lower.contains('mobilya')) {
      return Icons.chair_rounded;
    }
    if (lower.contains('ayakkabi')) {
      return Icons.shopping_bag_outlined;
    }
    return Icons.category_rounded;
  }
}
