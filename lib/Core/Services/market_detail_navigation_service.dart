import 'package:get/get.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_create_view.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/Market/market_my_items_view.dart';
import 'package:turqappv2/Modules/Market/market_offers_view.dart';
import 'package:turqappv2/Modules/Market/market_saved_view.dart';
import 'package:turqappv2/Modules/Market/market_search_view.dart';

class MarketDetailNavigationService {
  const MarketDetailNavigationService();

  Future<void> openMarketDetail(MarketItemModel item) async {
    await Get.to(() => MarketDetailView(item: item));
  }

  Future<dynamic> openMarketCreate({MarketItemModel? initialItem}) async {
    return Get.to(() => MarketCreateView(initialItem: initialItem));
  }

  Future<void> openMarketMyItems() async {
    await Get.to(() => const MarketMyItemsView());
  }

  Future<void> openMarketOffers() async {
    await Get.to(() => const MarketOffersView());
  }

  Future<void> openMarketSaved() async {
    await Get.to(() => const MarketSavedView());
  }

  Future<void> openMarketSearch() async {
    await Get.to(() => const MarketSearchView());
  }
}
