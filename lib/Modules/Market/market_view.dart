import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Buttons/action_button.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/Market/market_filter_sheet.dart';
import 'package:turqappv2/Themes/app_assets.dart';

class MarketView extends StatelessWidget {
  MarketView({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
  });

  final bool embedded;
  final bool showEmbeddedControls;
  final MarketController controller = Get.isRegistered<MarketController>()
      ? Get.find<MarketController>()
      : Get.put(MarketController());

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
                const Text(
                  'Market',
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
      floatingActionButton: showEmbeddedControls
          ? ActionButton(
              context: context,
              permissionScope: ActionButtonPermissionScope.none,
              menuItems: [
                PullDownMenuItem(
                  title: 'Ilan Ekle',
                  icon: CupertinoIcons.add_circled,
                  onTap: () => controller.openRoundMenu('create'),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Obx(() {
      return CustomScrollView(
        controller: controller.scrollController,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EducationSlider(
                  sliderId: 'market',
                  imageList: [
                    AppAssets.job1,
                    AppAssets.job2,
                    AppAssets.job3,
                  ],
                ),
                const SizedBox(height: 14),
                _buildRoundMenu(),
                const SizedBox(height: 12),
                _buildCategoryStrip(),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TurqSearchBar(
                    controller: controller.search,
                    hintText: 'Ne ariyorsun?',
                    onChanged: controller.setSearchQuery,
                  ),
                ),
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Vitrin Ilanlar',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: controller.toggleListingSelection,
                        child: Row(
                          children: [
                            Icon(
                              controller.listingSelection.value == 0
                                  ? Icons.grid_view_rounded
                                  : Icons.view_agenda_outlined,
                              size: 19,
                              color: Colors.black,
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'Gorunum',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                                fontFamily: 'MontserratMedium',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: const Size(25, 25),
                          fixedSize: const Size(30, 30),
                        ),
                        onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.white,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(24),
                            ),
                          ),
                          builder: (_) => MarketFilterSheet(
                            controller: controller,
                          ),
                        ),
                        child: Icon(
                          Icons.filter_alt_outlined,
                          color: controller.hasAdvancedFilters
                              ? Colors.pink
                              : Colors.black,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
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
                          if (controller.selectedContactFilter.value.isNotEmpty)
                            _buildFilterPill(
                              controller.selectedContactFilter.value == 'phone'
                                  ? 'Telefon'
                                  : 'Mesaj',
                            ),
                          if (controller.minPriceFilter.value.isNotEmpty)
                            _buildFilterPill(
                              'Min ${controller.minPriceFilter.value}',
                            ),
                          if (controller.maxPriceFilter.value.isNotEmpty)
                            _buildFilterPill(
                              'Max ${controller.maxPriceFilter.value}',
                            ),
                          if (controller.sortSelection.value != 'newest')
                            _buildFilterPill(
                              controller.sortSelection.value == 'price_asc'
                                  ? 'Fiyat Artan'
                                  : 'Fiyat Azalan',
                            ),
                          GestureDetector(
                            onTap: controller.clearAdvancedFilters,
                            child: const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Text(
                                'Temizle',
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
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              sliver: SliverList.builder(
                itemCount: controller.visibleItems.length,
                itemBuilder: (context, index) =>
                    _buildListingCard(controller.visibleItems[index]),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 16),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) =>
                      _buildGridCard(controller.visibleItems[index]),
                  childCount: controller.visibleItems.length,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.78,
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _buildRoundMenu() {
    return SizedBox(
      height: 98,
      child: Obx(() {
        final items = controller.roundMenuItems;
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final item = items[index];
            final color = _parseColor((item['accent'] ?? '#111827').toString());
            return GestureDetector(
              onTap: () =>
                  controller.openRoundMenu((item['key'] ?? '').toString()),
              child: SizedBox(
                width: 72,
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withValues(alpha: 0.12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        _iconFor((item['icon'] ?? 'apps').toString()),
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (item['label'] ?? '').toString(),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
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
      height: 44,
      child: Obx(() {
        final items = controller.categories.take(12).toList(growable: false);
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final category = items[index];
            final key = (category['key'] ?? '').toString();
            final selected = controller.selectedCategoryKey.value == key;
            final accent = _parseColor(
              (category['accent'] ?? '#111827').toString(),
            );
            return GestureDetector(
              onTap: () => controller.selectCategory(key),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: selected ? accent : Colors.white,
                  border: Border.all(
                    color: selected ? accent : const Color(0x22000000),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _iconFor((category['icon'] ?? 'category').toString()),
                      size: 16,
                      color: selected ? Colors.white : accent,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      (category['label'] ?? '').toString(),
                      style: TextStyle(
                        color: selected ? Colors.white : Colors.black,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                  ],
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
    return GestureDetector(
      onTap: () => controller.openItem(item),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
            color: Colors.white,
          ),
          child: Row(
            children: [
              _buildItemVisual(
                item,
                accent,
                width: 56,
                height: 56,
                radius: 12,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.locationText,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                        fontFamily: 'MontserratMedium',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: accent.withValues(alpha: 0.12),
                          ),
                          child: Text(
                            item.categoryLabel,
                            style: TextStyle(
                              color: accent,
                              fontSize: 10,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ),
                        if (item.offerCount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${item.offerCount} teklif',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 11,
                              fontFamily: 'MontserratMedium',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => controller.toggleSaved(item),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        controller.isSaved(item.id)
                            ? Icons.bookmark
                            : Icons.bookmark_outline,
                        color: Colors.black,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${item.price.toStringAsFixed(0)} TL',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(height: 18),
                  Icon(
                    CupertinoIcons.chevron_right,
                    color: Colors.grey.shade500,
                    size: 18,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(MarketItemModel item) {
    final accent = _accentForItem(item);
    return GestureDetector(
      onTap: () => controller.openItem(item),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _buildItemVisual(
                        item,
                        accent,
                        radius: 10,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => controller.toggleSaved(item),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            controller.isSaved(item.id)
                                ? Icons.bookmark
                                : Icons.bookmark_outline,
                            color: Colors.black,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.locationText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 11,
                  fontFamily: 'MontserratMedium',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${item.price.toStringAsFixed(0)} TL',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontFamily: 'MontserratBold',
                ),
              ),
            ],
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
          children: const [
            Icon(Icons.storefront_outlined, size: 42, color: Colors.black38),
            SizedBox(height: 10),
            Text(
              'Bu filtrede ilan bulunamadi.',
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
        return Icons.bookmark_outline;
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
}
