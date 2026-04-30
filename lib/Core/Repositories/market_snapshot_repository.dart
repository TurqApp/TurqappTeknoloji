import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/app_firestore.dart';
import 'package:turqappv2/Core/Services/CacheFirst/cache_first.dart';
import 'package:turqappv2/Core/Services/pasaj_feature_gate.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Education/pasaj_tabs.dart';

part 'market_snapshot_repository_data_part.dart';
part 'market_snapshot_repository_models_part.dart';
part 'market_snapshot_repository_facade_part.dart';
part 'market_snapshot_repository_support_part.dart';

class MarketSnapshotRepository extends GetxService {
  MarketSnapshotRepository();

  static const String _homeSurfaceKey = 'market_home_snapshot';
  static const String _searchSurfaceKey = 'market_search_snapshot';
  static const String _ownerSurfaceKey = 'market_owner_snapshot';

  static MarketSnapshotRepository? maybeFind() =>
      _maybeFindMarketSnapshotRepository();

  static MarketSnapshotRepository ensure() => _ensureMarketSnapshotRepository();

  late final CacheFirstCoordinator<List<MarketItemModel>> _coordinator =
      _createMarketSnapshotCoordinator(this);

  late final CacheFirstQueryPipeline<MarketListingQuery, List<MarketItemModel>,
          List<MarketItemModel>> _homePipeline =
      _createMarketSnapshotHomePipeline(this);

  late final CacheFirstQueryPipeline<MarketListingQuery, List<MarketItemModel>,
          List<MarketItemModel>> _searchPipeline =
      _createMarketSnapshotSearchPipeline(this);

  late final CacheFirstQueryPipeline<MarketOwnerQuery, List<MarketItemModel>,
          List<MarketItemModel>> _ownerPipeline =
      _createMarketSnapshotOwnerPipeline(this);
}
