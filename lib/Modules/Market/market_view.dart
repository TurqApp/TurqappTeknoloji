import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Services/market_contact_service.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/Widgets/pasaj_grid_card.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Core/Widgets/pasaj_listing_ad_layout.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Themes/app_assets.dart';

part 'market_view_filters_part.dart';
part 'market_view_cards_part.dart';
part 'market_view_style_part.dart';

class MarketView extends StatelessWidget {
  MarketView({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
    MarketController? controller,
  }) : controller = controller ?? MarketController.ensure();

  final bool embedded;
  final bool showEmbeddedControls;
  static const MarketContactService _contactService = MarketContactService();
  static bool _bannerWarmupTriggered = false;
  final MarketController controller;

  @override
  Widget build(BuildContext context) {
    if (!_bannerWarmupTriggered) {
      _bannerWarmupTriggered = true;
      unawaited(
        AdmobBannerWarmupService.ensure().warmForPasajEntry(
          surfaceKey: 'market',
        ),
      );
    }

    final content = Column(
      children: [
        const Divider(height: 1, color: Color(0xFFE0E0E0)),
        Expanded(child: _buildBody(context)),
      ],
    );

    if (embedded) {
      return content;
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                const AppBackButton(),
                const SizedBox(width: 8),
                Text(
                  'pasaj.market.title'.tr,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontFamily: 'MontserratBold',
                  ),
                ),
              ],
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      if (!controller.listingSelectionReady.value) {
        return const Center(child: CupertinoActivityIndicator());
      }
      return RefreshIndicator(
        onRefresh: controller.refreshHome,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMarketSlider(),
                  _buildCategoryStrip(),
                  const SizedBox(height: 8),
                  if (controller.hasAdvancedFilters)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            if (controller.selectedCityFilter.value.isNotEmpty)
                              _buildFilterPill(
                                  controller.selectedCityFilter.value),
                            if (controller
                                .selectedContactFilter.value.isNotEmpty)
                              _buildFilterPill(
                                controller.selectedContactFilter.value ==
                                        'phone'
                                    ? 'pasaj.market.contact_phone'.tr
                                    : 'pasaj.market.contact_message'.tr,
                              ),
                            if (controller.minPriceFilter.value.isNotEmpty)
                              _buildFilterPill(
                                'pasaj.market.min_price'
                                    .trParams(<String, String>{
                                  'value': controller.minPriceFilter.value,
                                }),
                              ),
                            if (controller.maxPriceFilter.value.isNotEmpty)
                              _buildFilterPill(
                                'pasaj.market.max_price'
                                    .trParams(<String, String>{
                                  'value': controller.maxPriceFilter.value,
                                }),
                              ),
                            if (controller.sortSelection.value != 'newest')
                              _buildFilterPill(
                                controller.sortSelection.value == 'price_asc'
                                    ? 'pasaj.market.sort_price_asc'.tr
                                    : 'pasaj.market.sort_price_desc'.tr,
                              ),
                            GestureDetector(
                              onTap: controller.clearAdvancedFilters,
                              child: Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Text(
                                  'common.clear'.tr,
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if ((controller.isLoading.value ||
                    controller.isSearchLoading.value) &&
                controller.visibleItems.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (controller.visibleItems.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _buildEmptyState(),
              )
            else if (controller.listingSelection.value == 0)
              SliverToBoxAdapter(
                key: const ValueKey<String>('market-listing-list'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Column(
                    children: PasajListingAdLayout.buildListChildren(
                      items: controller.visibleItems,
                      itemBuilder: (item, index) => _buildListingCard(item),
                      adBuilder: (slot) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: AdmobKare(
                          key: ValueKey('market-list-ad-$slot'),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                key: const ValueKey<String>('market-listing-grid'),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
                  child: Column(
                    children: PasajListingAdLayout.buildTwoColumnGridChildren(
                      items: controller.visibleItems,
                      horizontalSpacing: 4,
                      rowSpacing: 4,
                      itemBuilder: (item, index) => _buildGridCard(item),
                      adBuilder: (slot) => AdmobKare(
                        key: ValueKey('market-grid-ad-$slot'),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _MarketGridMedia extends StatefulWidget {
  const _MarketGridMedia({
    required this.item,
    required this.accent,
    required this.radius,
    required this.fallbackBuilder,
  });

  final MarketItemModel item;
  final Color accent;
  final double radius;
  final Widget Function(MarketItemModel item, Color accent) fallbackBuilder;

  @override
  State<_MarketGridMedia> createState() => _MarketGridMediaState();
}

class _MarketGridMediaState extends State<_MarketGridMedia> {
  late final PageController _pageController;
  int _pageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageUrls = widget.item.imageUrls
        .where((url) => url.trim().isNotEmpty)
        .toList(growable: false);
    final allImages = imageUrls.isNotEmpty
        ? imageUrls
        : (widget.item.coverImageUrl.trim().isNotEmpty
            ? <String>[widget.item.coverImageUrl]
            : const <String>[]);

    if (allImages.length <= 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Container(
          color: widget.accent.withValues(alpha: 0.12),
          child: allImages.isNotEmpty
              ? Image.network(
                  allImages.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) =>
                      widget.fallbackBuilder(widget.item, widget.accent),
                )
              : widget.fallbackBuilder(widget.item, widget.accent),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: Stack(
        children: [
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: allImages.length,
              onPageChanged: (value) {
                if (!mounted) return;
                setState(() {
                  _pageIndex = value;
                });
              },
              itemBuilder: (context, index) {
                return Container(
                  color: widget.accent.withValues(alpha: 0.12),
                  child: Image.network(
                    allImages[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) =>
                        widget.fallbackBuilder(widget.item, widget.accent),
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(allImages.length, (index) {
                final selected = index == _pageIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: selected ? 14 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
