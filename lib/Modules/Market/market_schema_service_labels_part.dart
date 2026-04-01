part of 'market_schema_service_library.dart';

class MarketSchemaServiceLabelsPart {
  const MarketSchemaServiceLabelsPart(this.service);

  final MarketSchemaService service;

  List<Map<String, dynamic>> roundMenuItems() {
    final ui = Map<String, dynamic>.from(
      service.schema['ui'] as Map? ?? const {},
    );
    final menu = (ui['recommendedRoundMenu'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map((item) {
      final mapped = Map<String, dynamic>.from(item);
      final key = (mapped['key'] ?? '').toString();
      final localized = roundMenuLabelFor(key);
      if (localized != null) {
        mapped['label'] = localized;
      }
      return mapped;
    }).toList(growable: false);
    return menu;
  }

  String? roundMenuLabelFor(String key) {
    switch (key) {
      case 'create':
        return 'pasaj.market.menu.create'.tr;
      case 'my_items':
        return 'pasaj.market.menu.my_items'.tr;
      case 'saved':
        return 'pasaj.market.menu.saved'.tr;
      case 'offers':
        return 'pasaj.market.menu.offers'.tr;
      case 'categories':
        return 'pasaj.market.menu.categories'.tr;
      case 'nearby':
        return 'pasaj.market.menu.nearby'.tr;
      default:
        return null;
    }
  }

  List<Map<String, dynamic>> categories() {
    return (service.schema['categories'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (item) => localizedCategoryNode(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList(growable: false);
  }

  Map<String, dynamic> localizedCategoryNode(Map<String, dynamic> node) {
    final mapped = Map<String, dynamic>.from(node);
    final key = (mapped['key'] ?? '').toString();
    final localized = categoryLabelFor(key);
    if (localized != null) {
      mapped['localizedLabel'] = localized;
    }
    final children = mapped['children'];
    if (children is List) {
      mapped['children'] = children
          .whereType<Map>()
          .map(
            (child) => localizedCategoryNode(
              Map<String, dynamic>.from(child),
            ),
          )
          .toList(growable: false);
    }
    return mapped;
  }

  String? categoryLabelFor(String key) {
    switch (key) {
      case 'elektronik':
        return 'pasaj.market.category.electronics'.tr;
      case 'telefon':
        return 'pasaj.market.category.phone'.tr;
      case 'bilgisayar':
        return 'pasaj.market.category.computer'.tr;
      case 'oyun-elektronigi':
        return 'pasaj.market.category.gaming_electronics'.tr;
      case 'giyim':
        return 'pasaj.market.category.clothing'.tr;
      case 'ev-yasam':
        return 'pasaj.market.category.home_living'.tr;
      case 'spor':
        return 'pasaj.market.category.sports'.tr;
      case 'emlak':
        return 'pasaj.market.category.real_estate'.tr;
      default:
        return null;
    }
  }
}

extension MarketSchemaServiceLabelsFacadePart on MarketSchemaService {
  List<Map<String, dynamic>> roundMenuItems() =>
      MarketSchemaServiceLabelsPart(this).roundMenuItems();

  List<Map<String, dynamic>> categories() =>
      MarketSchemaServiceLabelsPart(this).categories();
}
