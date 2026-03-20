import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Modules/Market/market_category_utils.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';

class _MarketCategoryNode {
  const _MarketCategoryNode({
    required this.key,
    required this.label,
    required this.pathLabels,
    required this.children,
  });

  final String key;
  final String label;
  final List<String> pathLabels;
  final List<_MarketCategoryNode> children;
}

class MarketCategorySheet extends StatefulWidget {
  const MarketCategorySheet({
    super.key,
    required this.controller,
    this.topLevelOnly = false,
  });

  final MarketController controller;
  final bool topLevelOnly;

  @override
  State<MarketCategorySheet> createState() => _MarketCategorySheetState();
}

class _MarketCategorySheetState extends State<MarketCategorySheet> {
  late final List<Map<String, dynamic>> _topCategories;
  late final List<_MarketCategoryNode> _topNodes;
  List<List<_MarketCategoryNode>> _categoryLevels =
      <List<_MarketCategoryNode>>[];
  List<_MarketCategoryNode> _selectedNodes = <_MarketCategoryNode>[];
  String _selectedTopKey = '';

  String _categoryLabel(Map<String, dynamic> category) {
    return (category['localizedLabel'] ?? category['label'] ?? '').toString();
  }

  @override
  void initState() {
    super.initState();
    _topCategories = widget.controller.categories
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    _topNodes = _topCategories
        .map(
          (item) => _buildNode(
            item,
            [_categoryLabel(item)],
          ),
        )
        .toList(growable: false);
    _hydrateSelection();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.topLevelOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          openTopLevelOnlyPicker().then((_) {
            if (mounted && Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
        }
      });
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 18, 15, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(title: 'pasaj.market.categories'.tr),
            const SizedBox(height: 12),
            _selectorTile(
              label: _selectedTopLabel ?? 'pasaj.market.create.main_category'.tr,
              onTap: _openTopCategorySheet,
            ),
            const SizedBox(height: 8),
            for (var level = 0; level < _categoryLevels.length; level++)
              if (_shouldShowLevel(level)) ...[
                _selectorTile(
                  label: _selectedNodes.length > level
                      ? _selectedNodes[level].label
                      : _levelLabel(level),
                  onTap: () => _openCategoryLevelSheet(level),
                ),
                const SizedBox(height: 8),
              ],
            if (_selectedPathText.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F7FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _selectedPathText,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    fontFamily: 'MontserratMedium',
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.controller.selectCategory('');
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      side: const BorderSide(color: Color(0x22000000)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'pasaj.market.all_categories'.tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontFamily: 'MontserratBold',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedCategoryKey.isEmpty
                        ? null
                        : () {
                            widget.controller
                                .selectCategory(_selectedCategoryKey);
                            Navigator.of(context).pop();
                          },
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'pasaj.market.filter.apply'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'MontserratBold',
                      ),
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

  String? get _selectedTopLabel {
    if (_selectedTopKey.isEmpty) return null;
    for (final item in _topCategories) {
      if ((item['key'] ?? '').toString() == _selectedTopKey) {
        return _categoryLabel(item);
      }
    }
    return null;
  }

  String get _selectedCategoryKey {
    if (_selectedNodes.isEmpty) return _selectedTopKey;
    return _selectedNodes.last.key;
  }

  String get _selectedPathText {
    if (_selectedNodes.isEmpty) return '';
    return _selectedNodes.last.pathLabels.skip(1).join(' > ');
  }

  void _hydrateSelection() {
    final selectedKey = widget.controller.selectedCategoryKey.value.trim();
    if (selectedKey.isEmpty && _topCategories.isNotEmpty) {
      _selectedTopKey = (_topCategories.first['key'] ?? '').toString();
      _rebuildCategorySelection();
      return;
    }

    if (selectedKey.isEmpty) return;

    for (var index = 0; index < _topNodes.length; index++) {
      final path = _findPath(_topNodes[index], selectedKey);
      if (path == null) continue;
      _selectedTopKey = (_topCategories[index]['key'] ?? '').toString();
      _rebuildCategorySelection(preferredPathKeys: path);
      return;
    }

    _selectedTopKey = (_topCategories.firstOrNull?['key'] ?? '').toString();
    _rebuildCategorySelection();
  }

  Future<void> _openTopCategorySheet() async {
    final displayToKey = <String, String>{
      for (final category in _topCategories)
        _categoryLabel(category):
            (category['key'] ?? '').toString(),
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
        setState(() {
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
        _categoryLabel(category):
            (category['key'] ?? '').toString(),
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
        setState(() {
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

  Widget _selectorTile({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontFamily: 'MontserratBold',
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

  List<_MarketCategoryNode> _optionsForLevel(int level) {
    if (level < 0 || level >= _categoryLevels.length) return const [];
    return _categoryLevels[level];
  }

  bool _shouldShowLevel(int level) => _optionsForLevel(level).length > 1;

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

  void _rebuildCategorySelection({List<String>? preferredPathKeys}) {
    _categoryLevels = <List<_MarketCategoryNode>>[];
    _selectedNodes = <_MarketCategoryNode>[];
    final topNode = _topNodes.firstWhere(
      (item) => item.key == _selectedTopKey,
      orElse: () => const _MarketCategoryNode(
        key: '',
        label: '',
        pathLabels: <String>[],
        children: <_MarketCategoryNode>[],
      ),
    );
    if (topNode.key.isEmpty || topNode.children.isEmpty) return;

    var options = topNode.children;
    var level = 0;
    final selected = <_MarketCategoryNode>[];

    while (options.isNotEmpty) {
      _categoryLevels.add(options);
      _MarketCategoryNode? nextSelection;
      if (preferredPathKeys != null && level < preferredPathKeys.length) {
        nextSelection = options
            .where((node) => node.key == preferredPathKeys[level])
            .firstOrNull;
      }
      nextSelection ??= options.length == 1 ? options.first : null;
      if (nextSelection == null) break;
      selected.add(nextSelection);
      options = nextSelection.children;
      level++;
    }

    _selectedNodes = selected;
  }

  _MarketCategoryNode _buildNode(
    Map<String, dynamic> node,
    List<String> path,
  ) {
    final rawChildren = (node['children'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    final children = <_MarketCategoryNode>[];
    final seen = <String>{};
    for (final child in rawChildren) {
      final label =
          (child['localizedLabel'] ?? child['label'] ?? '').toString().trim();
      if (label.isEmpty) continue;
      final dedupeKey =
          '${normalizeMarketNodeKey(label)}|${(child['key'] ?? '').toString().trim()}';
      if (!seen.add(dedupeKey)) continue;
      children.add(_buildNode(child, _appendPath(path, label)));
    }
    children.sort((a, b) => compareTurkishStrings(a.label, b.label));

    return _MarketCategoryNode(
      key: (node['key'] ?? '').toString(),
      label: (node['localizedLabel'] ?? node['label'] ?? '').toString(),
      pathLabels: path,
      children: children,
    );
  }

  List<String>? _findPath(_MarketCategoryNode node, String targetKey) {
    for (final child in node.children) {
      final nextPath = <String>[child.key];
      if (child.key == targetKey) return nextPath;
      final nested = _findPathFromChild(child, targetKey, nextPath);
      if (nested != null) return nested;
    }
    return null;
  }

  List<String>? _findPathFromChild(
    _MarketCategoryNode node,
    String targetKey,
    List<String> path,
  ) {
    if (node.key == targetKey) return path;
    for (final child in node.children) {
      final nested = _findPathFromChild(child, targetKey, [...path, child.key]);
      if (nested != null) return nested;
    }
    return null;
  }

  List<String> _appendPath(List<String> path, String label) {
    if (path.isNotEmpty &&
        normalizeMarketNodeKey(path.last) == normalizeMarketNodeKey(label)) {
      return path;
    }
    return [...path, label];
  }
}
