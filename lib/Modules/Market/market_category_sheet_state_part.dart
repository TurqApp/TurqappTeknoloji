part of 'market_category_sheet.dart';

extension _MarketCategorySheetStatePart on _MarketCategorySheetState {
  void _initializeCategoryState() {
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

  String _categoryLabel(Map<String, dynamic> category) {
    return (category['localizedLabel'] ?? category['label'] ?? '').toString();
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

  List<_MarketCategoryNode> _optionsForLevel(int level) {
    if (level < 0 || level >= _categoryLevels.length) return const [];
    return _categoryLevels[level];
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
