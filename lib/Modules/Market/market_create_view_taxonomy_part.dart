part of 'market_create_view.dart';

extension _MarketCreateViewTaxonomyPart on _MarketCreateViewState {
  String _categoryLabel(Map<String, dynamic> category) {
    return (category['localizedLabel'] ?? category['label'] ?? '').toString();
  }

  Widget _buildTopCategories() {
    String? selectedLabel;
    for (final category in controller.topCategories) {
      final key = (category['key'] ?? '').toString();
      if (key == controller.selectedTopKey.value) {
        selectedLabel = _categoryLabel(category);
        break;
      }
    }

    return GestureDetector(
      onTap: _openTopCategorySheet,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedLabel ?? 'pasaj.market.create.main_category'.tr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selectedLabel == null ? Colors.grey : Colors.black,
                  fontSize: 15,
                  fontFamily: selectedLabel == null
                      ? 'MontserratMedium'
                      : 'MontserratBold',
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openTopCategorySheet() async {
    final displayToKey = <String, String>{
      for (final category in controller.topCategories)
        _categoryLabel(category): (category['key'] ?? '').toString(),
    };
    String? selectedDisplay;
    for (final entry in displayToKey.entries) {
      if (entry.value == controller.selectedTopKey.value) {
        selectedDisplay = entry.key;
        break;
      }
    }

    await ListBottomSheet.show(
      context: context,
      items: displayToKey.keys.toList(growable: false),
      title: 'pasaj.market.create.main_category'.tr,
      searchHintText: 'pasaj.market.create.main_category_search'.tr,
      searchTextBuilder: (item) =>
          _topCategorySearchText(displayToKey[item.toString()] ?? ''),
      selectedItem: selectedDisplay,
      onSelect: (selectedLabel) {
        final key = displayToKey[selectedLabel.toString()];
        if (key != null) {
          controller.selectTopCategory(key);
          Future.delayed(
            const Duration(milliseconds: 180),
            () => _openNextCategoryLevelSheet(fromLevel: -1),
          );
        }
      },
    );
  }

  String _topCategorySearchText(String topKey) {
    final category = controller.topCategories.firstWhereOrNull(
      (item) => (item['key'] ?? '').toString() == topKey,
    );
    if (category == null) return '';
    final parts = <String>[];

    void walk(dynamic node) {
      if (node is! Map) return;
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

    walk(category);
    return parts.join(' ');
  }

  Widget _buildCategoryLevels() {
    if (controller.categoryLevels.isEmpty) {
      return _infoBox('pasaj.market.create.no_subcategory'.tr);
    }

    return Column(
      children: [
        for (var level = 0; level < controller.categoryLevels.length; level++)
          if (controller.shouldShowLevel(level)) ...[
            _buildCategorySelector(level),
            const SizedBox(height: 8),
          ],
      ],
    );
  }

  String _levelLabel(int level) {
    switch (level) {
      case 0:
        return 'pasaj.market.create.subcategory'.tr;
      case 1:
        return 'pasaj.market.create.subgroup'.tr;
      case 2:
        return 'pasaj.market.create.product_type'.tr;
      default:
        return 'pasaj.market.create.level'.trParams({'value': '${level + 1}'});
    }
  }

  Widget _buildCategorySelector(int level) {
    final selected = controller.selectedNodeForLevel(level);
    return GestureDetector(
      onTap: () => _openCategoryLevelSheet(level),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selected?.label ?? _levelLabel(level),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected == null ? Colors.grey : Colors.black,
                  fontSize: 15,
                  fontFamily:
                      selected == null ? 'MontserratMedium' : 'MontserratBold',
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_down,
              size: 18,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCategoryLevelSheet(int level) async {
    final nodes = controller.optionsForLevel(level);
    if (nodes.isEmpty) return;

    final displayToKey = <String, String>{};
    final seenCounts = <String, int>{};
    for (final node in nodes) {
      final duplicateCount =
          nodes.where((candidate) => candidate.label == node.label).length;
      var display =
          duplicateCount > 1 ? node.pathLabels.skip(1).join(' > ') : node.label;
      if (display.trim().isEmpty) {
        display = node.label;
      }
      final existing = seenCounts[display] ?? 0;
      seenCounts[display] = existing + 1;
      if (existing > 0) {
        display = '$display (${existing + 1})';
      }
      displayToKey[display] = node.key;
    }

    final selectedNode = controller.selectedNodeForLevel(level);
    String? selectedDisplay;
    for (final entry in displayToKey.entries) {
      if (entry.value == selectedNode?.key) {
        selectedDisplay = entry.key;
        break;
      }
    }

    await ListBottomSheet.show(
      context: context,
      items: displayToKey.keys.toList(growable: false),
      title: _levelLabel(level),
      selectedItem: selectedDisplay,
      onSelect: (selectedDisplayValue) {
        final key = displayToKey[selectedDisplayValue.toString()];
        if (key != null) {
          controller.selectNodeAtLevel(level, key);
          Future.delayed(
            const Duration(milliseconds: 180),
            () => _openNextCategoryLevelSheet(fromLevel: level),
          );
        }
      },
    );
  }

  Future<void> _openNextCategoryLevelSheet({required int fromLevel}) async {
    for (var nextLevel = fromLevel + 1;
        nextLevel < controller.categoryLevels.length;
        nextLevel++) {
      if (controller.shouldShowLevel(nextLevel)) {
        await _openCategoryLevelSheet(nextLevel);
        return;
      }
    }
  }
}
