import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turqappv2/Core/Services/read_budget_registry.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Core/Services/typesense_market_service.dart';

part 'market_repository_query_part.dart';
part 'market_repository_action_part.dart';
part 'market_repository_models_part.dart';
part 'market_repository_cache_part.dart';

class MarketRepository extends GetxService {
  MarketRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const Duration _ttl = Duration(hours: 3);
  static const String _prefsPrefix = 'market_repository_v1';
  final Map<String, _TimedMarketItems> _memory = <String, _TimedMarketItems>{};
  SharedPreferences? _prefs;

  static MarketRepository? maybeFind() {
    final isRegistered = Get.isRegistered<MarketRepository>();
    if (!isRegistered) return null;
    return Get.find<MarketRepository>();
  }

  static MarketRepository ensure() {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(MarketRepository(), permanent: true);
  }

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }

  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _firestore.collection('marketStore');
}
