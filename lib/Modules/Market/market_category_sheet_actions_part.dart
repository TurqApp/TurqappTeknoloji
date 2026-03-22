part of 'market_category_sheet.dart';

extension _MarketCategorySheetActionsPart on _MarketCategorySheetState {
  Future<void> _openTopCategorySheet() async {
    final displayToKey = <String, String>{
      for (final category in _topCategories)
        _categoryLabel(category): (category['key'] ?? '').toString(),
    };
    String? selectedDisplay;
    for (final entry in displayToKey.entries) {
      if (entry.value == _selectedTopKey) {
        selectedDisplay = entry.key;
        break;
      }
    }

    await ListBottomSheet.show(
      context: context,
      items: displayToKey.keys.toList(growable: false),
      title: 'pasaj.market.create.main_category'.tr,
      searchHintText: 'pasaj.market.category_search_hint'.tr,
      selectedItem: selectedDisplay,
      onSelect: (selectedLabel) {
        final key = displayToKey[selectedLabel.toString()];
        if (key == null) return;
        _updateViewState(() {
          _selectedTopKey = key;
          _rebuildCategorySelection();
        });
        Future.delayed(
          const Duration(milliseconds: 180),
          () => _openNextCategoryLevelSheet(fromLevel: -1),
        );
      },
    );
  }

  Future<void> openTopLevelOnlyPicker() async {
    final displayToKey = <String, String>{
      for (final category in _topCategories)
        _categoryLabel(category): (category['key'] ?? '').toString(),
    };

    String? selectedDisplay;
    for (final entry in displayToKey.entries) {
      if (entry.value == widget.controller.selectedCategoryKey.value.trim()) {
        selectedDisplay = entry.key;
        break;
      }
    }

    await ListBottomSheet.show(
      context: context,
      items: displayToKey.keys.toList(growable: false),
      title: 'pasaj.market.main_categories'.tr,
      searchHintText: 'pasaj.market.category_search_hint'.tr,
      selectedItem: selectedDisplay,
      onSelect: (selectedLabel) {
        final key = displayToKey[selectedLabel.toString()];
        if (key == null) return;
        widget.controller.selectCategory(key);
      },
    );
  }

  Future<void> _openCategoryLevelSheet(int level) async {
    final nodes = _optionsForLevel(level);
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

    String? selectedDisplay;
    if (_selectedNodes.length > level) {
      final selectedNode = _selectedNodes[level];
      for (final entry in displayToKey.entries) {
        if (entry.value == selectedNode.key) {
          selectedDisplay = entry.key;
          break;
        }
      }
    }

    await ListBottomSheet.show(
      context: context,
      items: displayToKey.keys.toList(growable: false),
      title: _levelLabel(level),
      searchHintText: 'pasaj.market.category_search_hint'.tr,
      selectedItem: selectedDisplay,
      onSelect: (selectedDisplayValue) {
        final key = displayToKey[selectedDisplayValue.toString()];
        if (key == null) return;
        _updateViewState(() {
          _selectNodeAtLevel(level, key);
        });
        Future.delayed(
          const Duration(milliseconds: 180),
          () => _openNextCategoryLevelSheet(fromLevel: level),
        );
      },
    );
  }

  Future<void> _openNextCategoryLevelSheet({required int fromLevel}) async {
    for (var nextLevel = fromLevel + 1;
        nextLevel < _categoryLevels.length;
        nextLevel++) {
      if (_shouldShowLevel(nextLevel)) {
        await _openCategoryLevelSheet(nextLevel);
        return;
      }
    }
  }

  void _selectNodeAtLevel(int level, String key) {
    if (level < 0 || level >= _categoryLevels.length) return;
    final node = _categoryLevels[level].firstWhere(
      (item) => item.key == key,
    );
    final preservedPath = <String>[
      for (var i = 0; i < level && i < _selectedNodes.length; i++)
        _selectedNodes[i].key,
      node.key,
    ];
    _rebuildCategorySelection(preferredPathKeys: preservedPath);
  }
}
