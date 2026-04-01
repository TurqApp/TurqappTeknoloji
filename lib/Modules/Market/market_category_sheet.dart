import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Utils/turkish_sort.dart';
import 'package:turqappv2/Modules/Market/market_category_utils.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';

part 'market_category_sheet_actions_part.dart';
part 'market_category_sheet_content_part.dart';
part 'market_category_sheet_state_part.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeCategoryState();
  }

  void _updateViewState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
