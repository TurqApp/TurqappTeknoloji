import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Core/Widgets/turq_search_bar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/Market/market_filter_sheet.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';

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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 15, 0),
              child: Row(
                children: [
                  const AppBackButton(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TurqSearchBar(
                      controller: controller.search,
                      focusNode: _focusNode,
                      hintText: 'pasaj.market.search_hint'.tr,
                      onChanged: controller.setSearchQuery,
                      onClear: () => controller.setSearchQuery(''),
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
                final showRecentSearches = query.length < 2;
                final items = controller.visibleItems;

                if (!showRecentSearches &&
                    controller.isSearchLoading.value &&
                    items.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (showRecentSearches) {
                  return _buildRecentSearches();
                }

                if (items.isEmpty) {
                  return _buildInfoState(
                    icon: CupertinoIcons.cube_box,
                    title: 'common.no_results'.tr,
                    subtitle: 'pasaj.market.search.no_results_body'.tr,
                  );
                }

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
                      child: Row(
                        children: [
                          Text(
                            'pasaj.market.search.result_count'
                                .trParams({'count': '${items.length}'}),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 13,
                              fontFamily: 'MontserratBold',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: ListView.builder(
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

  Widget _buildSavedIcon(MarketItemModel item) {
    return Obx(
      () => GestureDetector(
        onTap: () => controller.toggleSaved(item),
        child: Icon(
          controller.isSaved(item.id) ? AppIcons.saved : AppIcons.save,
          color: controller.isSaved(item.id)
              ? Colors.orange
              : Colors.grey.shade600,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildRecentSearches() {
    return Obx(() {
      final items = controller.recentSearches;
      if (items.isEmpty) {
        return _buildInfoState(
          icon: CupertinoIcons.search,
          title: 'pasaj.market.search.start_title'.tr,
          subtitle: 'pasaj.market.search.start_body'.tr,
        );
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 20),
        children: [
          Row(
            children: [
              Text(
                'pasaj.market.search.recent'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'MontserratBold',
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: controller.clearRecentSearches,
                child: Text(
                  'common.clear'.tr,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(
                CupertinoIcons.time,
                color: Colors.black45,
                size: 18,
              ),
              title: Text(
                item,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontFamily: 'MontserratMedium',
                ),
              ),
              trailing: const Icon(
                CupertinoIcons.arrow_up_left,
                color: Colors.black45,
                size: 16,
              ),
              onTap: () => controller.applyRecentSearch(item),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildInfoState({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(
          32,
          24,
          32,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
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
              if ((subtitle ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 13,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ],
            ],
          ),
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
                    '${_formattedPrice(item.price)} ${_currencyLabel(item.currency)}',
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
                _buildSavedIcon(item),
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
}
