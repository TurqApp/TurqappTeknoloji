import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/Market/market_filter_sheet.dart';

class MarketSearchView extends StatefulWidget {
  const MarketSearchView({super.key});

  @override
  State<MarketSearchView> createState() => _MarketSearchViewState();
}

class _MarketSearchViewState extends State<MarketSearchView> {
  late final MarketController controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<MarketController>()
        ? Get.find<MarketController>()
        : Get.put(MarketController());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 15, 0),
              child: Row(
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
                  Expanded(
                    child: TurqSearchBar(
                      controller: controller.search,
                      focusNode: _focusNode,
                      hintText: 'İlan ara',
                      onChanged: controller.setSearchQuery,
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: const Size(30, 30),
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
                      builder: (_) => MarketFilterSheet(controller: controller),
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
            Expanded(
              child: Obx(() {
                final query = controller.searchQuery.value.trim();
                final items = controller.visibleItems;

                if (query.length < 2) {
                  return _buildInfoState(
                    icon: CupertinoIcons.search,
                    title: 'İlan aramaya başla',
                    subtitle: 'En az 2 karakter yazarak market içinde ara.',
                  );
                }

                if (controller.isSearchLoading.value && items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (items.isEmpty) {
                  return _buildInfoState(
                    icon: CupertinoIcons.cube_box,
                    title: 'Sonuç bulunamadı',
                    subtitle: 'Aramana uygun ilan bulunmuyor.',
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                      child: Row(
                        children: [
                          Text(
                            '${items.length} sonuç',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: controller.toggleListingSelection,
                            child: Row(
                              children: [
                                Icon(
                                  controller.listingSelection.value == 0
                                      ? Icons.grid_view_rounded
                                      : Icons.view_agenda_outlined,
                                  size: 18,
                                  color: Colors.black,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Görünüm',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 13,
                                    fontFamily: 'MontserratMedium',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: controller.listingSelection.value == 0
                            ? GridView.builder(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                gridDelegate:
                                    const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 220,
                                  mainAxisSpacing: 8,
                                  crossAxisSpacing: 8,
                                  childAspectRatio: 0.78,
                                ),
                                itemCount: items.length,
                                itemBuilder: (context, index) =>
                                    _buildGridCard(items[index]),
                              )
                            : ListView.builder(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                itemCount: items.length,
                                itemBuilder: (context, index) =>
                                    _buildListCard(items[index]),
                              ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black26, size: 34),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'MontserratBold',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontFamily: 'MontserratMedium',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListCard(MarketItemModel item) {
    final accent = _accentForItem(item);
    return GestureDetector(
      onTap: () => controller.openItem(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
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
              width: 65,
              height: 65,
              radius: 8,
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontFamily: 'MontserratMedium',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.price.toStringAsFixed(0)} ${item.currency.toUpperCase() == 'TRY' ? 'TL' : item.currency}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
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
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: _statusColor(item.status).withValues(alpha: 0.12),
                  ),
                  child: Text(
                    _statusLabel(item.status),
                    style: TextStyle(
                      color: _statusColor(item.status),
                      fontSize: 10,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                ),
              ],
            ),
          ],
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                _buildItemVisual(
                  item,
                  accent,
                  width: double.infinity,
                  height: 135,
                  radius: 12,
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => controller.toggleSaved(item),
                    child: Container(
                      width: 30,
                      height: 30,
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${item.price.toStringAsFixed(0)} ${item.currency.toUpperCase() == 'TRY' ? 'TL' : item.currency}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                    const Spacer(),
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
                  ],
                ),
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
    required double width,
    required double height,
    required double radius,
  }) {
    final imageUrl = item.coverImageUrl.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        width: width,
        height: height,
        color: accent.withValues(alpha: 0.1),
        child: imageUrl.isEmpty
            ? Icon(
                CupertinoIcons.cube_box_fill,
                color: accent,
                size: 26,
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  CupertinoIcons.cube_box_fill,
                  color: accent,
                  size: 26,
                ),
              ),
      ),
    );
  }

  Color _accentForItem(MarketItemModel item) {
    if (item.categoryKey.contains('elektronik')) return const Color(0xFF0F766E);
    if (item.categoryKey.contains('giyim')) return const Color(0xFF9D174D);
    if (item.categoryKey.contains('ev')) return const Color(0xFFB45309);
    if (item.categoryKey.contains('kitap')) return const Color(0xFF4338CA);
    return const Color(0xFF111827);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'sold':
        return const Color(0xFFB91C1C);
      case 'reserved':
        return const Color(0xFFB45309);
      case 'draft':
        return const Color(0xFF475569);
      case 'archived':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF0F766E);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'sold':
        return 'Satıldı';
      case 'reserved':
        return 'Rezerve';
      case 'draft':
        return 'Taslak';
      case 'archived':
        return 'Arşiv';
      default:
        return 'Aktif';
    }
  }
}
