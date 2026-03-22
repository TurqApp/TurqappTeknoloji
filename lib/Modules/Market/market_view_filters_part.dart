part of 'market_view.dart';

extension _MarketViewFiltersPart on MarketView {
  String _categoryLabel(Map<String, dynamic> category) {
    return (category['localizedLabel'] ?? category['label'] ?? '').toString();
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
}
