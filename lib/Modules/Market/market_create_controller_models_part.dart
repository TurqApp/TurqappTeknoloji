part of 'market_create_controller.dart';

class MarketLeafCategory {
  MarketLeafCategory({
    required this.key,
    required this.label,
    required this.pathLabels,
    required this.fields,
    required this.meta,
  });

  final String key;
  final String label;
  final List<String> pathLabels;
  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> meta;

  String get pathText => pathLabels.join(' > ');
  String get pathTextWithoutTop =>
      pathLabels.length <= 1 ? pathText : pathLabels.skip(1).join(' > ');
}

class MarketCategoryNode {
  MarketCategoryNode({
    required this.key,
    required this.label,
    required this.pathLabels,
    required this.fields,
    required this.meta,
    required this.children,
  });

  final String key;
  final String label;
  final List<String> pathLabels;
  final List<Map<String, dynamic>> fields;
  final Map<String, dynamic> meta;
  final List<MarketCategoryNode> children;

  bool get isLeaf => children.isEmpty;

  MarketLeafCategory toLeaf() => MarketLeafCategory(
        key: key,
        label: label,
        pathLabels: pathLabels,
        fields: fields,
        meta: meta,
      );
}

extension MarketCreateControllerRuntimePart on MarketCreateController {
  void _handleMarketCreateInit() {
    load();
  }

  void _handleMarketCreateClose() {
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    for (final controller in _fieldControllers.values) {
      controller.dispose();
    }
  }
}
