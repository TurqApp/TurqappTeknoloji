import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/market_contact_service.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_listing_ad_layout.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Themes/app_assets.dart';

class MarketView extends StatelessWidget {
  MarketView({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
    MarketController? controller,
  }) : controller = controller ??
            (Get.isRegistered<MarketController>()
                ? Get.find<MarketController>()
                : Get.put(MarketController()));

  final bool embedded;
  final bool showEmbeddedControls;
  static const MarketContactService _contactService = MarketContactService();
  final MarketController controller;

  String _categoryLabel(Map<String, dynamic> category) {
    return (category['localizedLabel'] ?? category['label'] ?? '').toString();
  }

  @override
  Widget build(BuildContext context) {
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
                TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      CupertinoIcons.arrow_left,
                      color: Colors.black,
                      size: 25,
                    ),
                  ),
                ),
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

  Widget _buildMarketSlider() {
    return const Column(
      children: [
        EducationSlider(
          sliderId: 'market',
          imageList: [
            AppAssets.job1,
            AppAssets.job2,
            AppAssets.job3,
          ],
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Future<void> _openTopCategoryList(BuildContext context) async {
    final displayToKey = <String, String>{
      'pasaj.market.all_listings'.tr: '',
      for (final category in controller.categories)
        _categoryLabel(category): (category['key'] ?? '').toString(),
    };

    String? selectedDisplay = 'pasaj.market.all_listings'.tr;
    if (controller.selectedCategoryKey.value.isNotEmpty) {
      for (final entry in displayToKey.entries) {
        if (entry.value == controller.selectedCategoryKey.value) {
          selectedDisplay = entry.key;
          break;
        }
      }
    }

    await ListBottomSheet.show(
      context: context,
      items: displayToKey.keys.toList(growable: false),
      title: 'pasaj.market.main_categories'.tr,
      searchHintText: 'pasaj.market.category_search_hint'.tr,
      searchTextBuilder: (item) =>
          _topCategorySearchText(displayToKey[item.toString()] ?? ''),
      selectedItem: selectedDisplay,
      onSelect: (selectedLabel) {
        final key = displayToKey[selectedLabel.toString()];
        if (key == null) return;
        controller.selectCategory(key);
      },
    );
  }

  String _topCategorySearchText(String topKey) {
    final category = controller.categories.firstWhereOrNull(
      (item) => (item['key'] ?? '').toString() == topKey,
    );
    if (category == null) return '';
    final parts = <String>[];
    void walk(dynamic node) {
      if (node is Map) {
        final label =
            (node['localizedLabel'] ?? node['label'] ?? '').toString().trim();
        final key = (node['key'] ?? '').toString().trim();
        if (label.isNotEmpty) parts.add(label);
        if (key.isNotEmpty) parts.add(key.replaceAll('-', ' '));
        final options = node['options'];
        if (options is List) {
          for (final option in options) {
            if (option is Map) {
              walk(option);
            } else {
              final value = option.toString().trim();
              if (value.isNotEmpty) parts.add(value);
            }
          }
        }
        final fields = node['fields'];
        if (fields is List) {
          for (final field in fields) {
            walk(field);
          }
        }
        final children = node['children'];
        if (children is List) {
          for (final child in children) {
            walk(child);
          }
        }
      }
    }

    walk(category);
    return parts.join(' ');
  }

  Widget _buildFilterPill(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(40),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 12,
          fontFamily: 'MontserratBold',
        ),
      ),
    );
  }

  Widget _buildCategoryStrip() {
    return SizedBox(
      height: 85,
      child: Obx(() {
        final items = controller.categories.toList(growable: false);
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          scrollDirection: Axis.horizontal,
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(width: 0),
          itemBuilder: (context, index) {
            if (index == 0) {
              return GestureDetector(
                onTap: () => _openTopCategoryList(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: SizedBox(
                    width: 68,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.apps_rounded,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 14,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'common.all'.tr,
                              maxLines: 1,
                              softWrap: false,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontFamily:
                                    controller.selectedCategoryKey.value.isEmpty
                                        ? 'MontserratBold'
                                        : 'MontserratMedium',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
            final category = items[index - 1];
            final key = (category['key'] ?? '').toString();
            final selected = controller.selectedCategoryKey.value == key;
            final accent = _parseColor(
              (category['accent'] ?? '#111827').toString(),
            );
            return GestureDetector(
              onTap: () => controller.selectCategory(key),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  width: 68,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          _categoryIconFor(category),
                          size: 30,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 14,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            _categoryLabel(category),
                            maxLines: 1,
                            softWrap: false,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 10,
                              fontFamily: selected
                                  ? 'MontserratBold'
                                  : 'MontserratMedium',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildListingCard(MarketItemModel item) {
    final accent = _accentForItem(item);
    final statusColor = _statusColor(item.status);
    final canCall = item.canShowPhone;
    return GestureDetector(
      onTap: () => controller.openItem(item),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
            color: Colors.white,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 360;
              final visualSize = compact ? 92.0 : 108.0;
              final actionButtonSize = compact ? 32.0 : 36.0;
              final actionIconSize = compact ? 16.0 : 18.0;
              final buttonText = canCall
                  ? 'pasaj.market.call_now'.tr
                  : 'pasaj.market.inspect'.tr;

              Widget actionButtons() {
                final children = [
                  AppHeaderActionButton(
                    onTap: () => const MarketShareService().shareItem(item),
                    size: actionButtonSize,
                    child: Icon(
                      AppIcons.share,
                      color: Colors.black.withValues(alpha: 0.85),
                      size: actionIconSize,
                    ),
                  ),
                  SizedBox(width: compact ? 0 : 6, height: compact ? 6 : 0),
                  AppHeaderActionButton(
                    onTap: () => controller.toggleSaved(
                      item,
                      showSnackbar: false,
                    ),
                    size: actionButtonSize,
                    child: Transform.flip(
                      flipX: true,
                      child: Icon(
                        controller.isSaved(item.id)
                            ? AppIcons.liked
                            : AppIcons.like,
                        color: controller.isSaved(item.id)
                            ? const Color(0xFF2563EB)
                            : Colors.grey.shade600,
                        size: compact ? 18 : 20,
                      ),
                    ),
                  ),
                ];

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildItemVisual(
                    item,
                    accent,
                    width: visualSize,
                    height: visualSize,
                    radius: 10,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: visualSize),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          maxLines: compact ? 2 : 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: compact ? 14 : 15,
                                            fontFamily: 'MontserratBold',
                                          ),
                                        ),
                                        const SizedBox(height: 1),
                                        Text(
                                          item.status == 'active'
                                              ? item.categoryLabel
                                              : _statusLabel(item.status),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: item.status == 'active'
                                                ? accent
                                                : statusColor,
                                            fontSize: 12,
                                            fontFamily: 'MontserratBold',
                                          ),
                                        ),
                                        if (item.description
                                            .trim()
                                            .isNotEmpty) ...[
                                          const SizedBox(height: 1),
                                          Text(
                                            item.description.trim(),
                                            maxLines: compact ? 2 : 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey.shade700,
                                              fontSize: 12,
                                              height: 1.1,
                                              fontFamily: 'MontserratMedium',
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (!compact) actionButtons(),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.locationText,
                                      maxLines: compact ? 2 : 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                        fontFamily: 'MontserratMedium',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Text(
                                  '${_formattedPrice(item.price)} ${_currencyLabel(item.currency)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Color(0xFF8B0000),
                                    fontSize: compact ? 16 : 17,
                                    fontFamily: 'MontserratBold',
                                  ),
                                ),
                              ),
                              SizedBox(width: compact ? 8 : 10),
                              GestureDetector(
                                onTap: () {
                                  if (canCall) {
                                    _contactService.callPhone(item);
                                  } else {
                                    controller.openItem(item);
                                  }
                                },
                                child: Container(
                                  constraints: BoxConstraints(
                                    minWidth: compact ? 104 : 118,
                                  ),
                                  height: compact ? 30 : 28,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: compact ? 14 : 16,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color:
                                        canCall ? Colors.green : Colors.black,
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    buttonText,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: compact ? 11 : 12,
                                      fontFamily: 'MontserratMedium',
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (compact) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: actionButtons(),
                            ),
                          ],
                        ],
                      ),
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
    return GestureDetector(
      onTap: () => controller.openItem(item),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.78,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: _MarketGridMedia(
                      item: item,
                      accent: accent,
                      radius: 12,
                      fallbackBuilder: (marketItem, marketAccent) =>
                          _buildItemFallback(marketItem, marketAccent),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () =>
                          controller.toggleSaved(item, showSnackbar: false),
                      child: Column(
                        children: [
                          Transform.flip(
                            flipX: true,
                            child: Icon(
                              controller.isSaved(item.id)
                                  ? AppIcons.liked
                                  : AppIcons.like,
                              color: Colors.white,
                              size: 26,
                              shadows: const [
                                Shadow(
                                  color: Color(0x55000000),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          if (item.favoriteCount > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              '${item.favoriteCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontFamily: 'MontserratBold',
                                shadows: [
                                  Shadow(
                                    color: Color(0x55000000),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.status == 'active'
                        ? item.categoryLabel
                        : _statusLabel(item.status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: item.status == 'active' ? accent : statusColor,
                      fontSize: 12,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.locationText.isNotEmpty
                              ? item.locationText
                              : item.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontFamily: 'MontserratMedium',
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
                          style: const TextStyle(
                            color: Color(0xFF8B0000),
                            fontSize: 19,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: canCall ? Colors.green : Colors.black,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        if (canCall) {
                          _contactService.callPhone(item);
                        } else {
                          controller.openItem(item);
                        }
                      },
                      child: Center(
                        child: Text(
                          canCall
                              ? 'pasaj.market.call_now'.tr
                              : 'pasaj.market.inspect'.tr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
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

  Color _accentForItem(MarketItemModel item) {
    final lower = item.categoryKey.toLowerCase();
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

  Color _statusColor(String status) {
    switch (status) {
      case 'sold':
        return const Color(0xFFB91C1C);
      case 'reserved':
        return const Color(0xFF2563EB);
      case 'draft':
        return const Color(0xFF7C3AED);
      case 'archived':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF111827);
    }
  }

  String _currencyLabel(String value) {
    final normalized = value.trim().toUpperCase();
    if (normalized == 'TRY') return 'TL';
    return value.trim();
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
    final lower = '${item.categoryKey} ${item.categoryLabel}'.toLowerCase();
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

  Color _parseColor(String raw) {
    final normalized = raw.replaceFirst('#', '');
    final value = int.tryParse('FF$normalized', radix: 16) ?? 0xFF111827;
    return Color(value);
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'add_circle':
        return Icons.add_circle;
      case 'inventory_2':
        return Icons.inventory_2_outlined;
      case 'bookmark':
        return Icons.thumb_up_alt_outlined;
      case 'thumb_up':
        return Icons.thumb_up_alt_outlined;
      case 'local_offer':
        return Icons.local_offer_outlined;
      case 'apps':
        return Icons.apps_rounded;
      case 'near_me':
        return Icons.near_me_outlined;
      case 'devices':
        return Icons.devices_rounded;
      case 'phone':
      case 'phone_iphone':
        return Icons.phone_iphone_rounded;
      case 'computer':
      case 'laptop_mac':
        return Icons.laptop_mac_rounded;
      case 'joystick':
      case 'sports_esports':
        return Icons.sports_esports_rounded;
      case 'style':
      case 'checkroom':
        return Icons.checkroom_rounded;
      case 'weekend':
      case 'chair':
        return Icons.chair_rounded;
      case 'exercise':
      case 'sports_soccer':
        return Icons.sports_soccer_rounded;
      case 'child_friendly':
      case 'baby_changing_station':
        return Icons.child_friendly_rounded;
      case 'apartment':
      case 'home_work':
        return Icons.home_work_outlined;
      case 'pets':
        return Icons.pets_outlined;
      case 'directions_car':
        return Icons.directions_car_outlined;
      case 'motorcycle':
        return Icons.two_wheeler_outlined;
      case 'menu_book':
        return Icons.menu_book_outlined;
      case 'brush':
        return Icons.brush_outlined;
      case 'build':
        return Icons.build_outlined;
      case 'toys':
        return Icons.toys_outlined;
      default:
        return Icons.category_rounded;
    }
  }

  IconData _categoryIconFor(Map<String, dynamic> category) {
    final label = (category['label'] ?? '').toString().toLowerCase();
    final key = (category['key'] ?? '').toString().toLowerCase();
    final lookup = '$label $key';

    if (lookup.contains('emlak')) return Icons.home_work_outlined;
    if (lookup.contains('telefon')) return Icons.phone_iphone_rounded;
    if (lookup.contains('elektronik')) return Icons.devices_rounded;
    if (lookup.contains('ev') || lookup.contains('yasam')) {
      return Icons.chair_rounded;
    }
    if (lookup.contains('motosiklet')) return Icons.two_wheeler_rounded;
    if (lookup.contains('giyim')) return Icons.checkroom_rounded;
    if (lookup.contains('kozmetik') || lookup.contains('kişisel')) {
      return Icons.face_retouching_natural_rounded;
    }
    if (lookup.contains('anne') || lookup.contains('bebek')) {
      return Icons.child_friendly_rounded;
    }
    if (lookup.contains('hobi')) return Icons.palette_outlined;
    if (lookup.contains('ofis')) return Icons.work_outline_rounded;
    if (lookup.contains('spor')) return Icons.sports_soccer_rounded;
    if (lookup.contains('kitap')) return Icons.menu_book_rounded;
    if (lookup.contains('oyuncak')) return Icons.toys_rounded;
    if (lookup.contains('pet')) return Icons.pets_rounded;
    if (lookup.contains('antika')) return Icons.auto_awesome_outlined;
    if (lookup.contains('yapi market')) return Icons.handyman_rounded;
    return _iconFor((category['icon'] ?? 'category').toString());
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
