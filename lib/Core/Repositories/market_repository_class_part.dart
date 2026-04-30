part of 'market_repository_library.dart';

abstract class _MarketRepositoryBase extends GetxService {
  _MarketRepositoryBase({FirebaseFirestore? firestore})
      : _state = _MarketRepositoryState(firestore: firestore);
  final _MarketRepositoryState _state;
  @override
  void onInit() {
    super.onInit();
    ensureLocalPreferenceRepository()
        .sharedPreferences()
        .then((prefs) => _state.prefs = prefs);
  }
}

class MarketRepository extends _MarketRepositoryBase {
  MarketRepository({super.firestore});
  static const Duration _ttl = Duration(hours: 3);
  static const String _prefsPrefix = 'market_repository_v1';
}

MarketRepository? maybeFindMarketRepository() =>
    Get.isRegistered<MarketRepository>() ? Get.find<MarketRepository>() : null;

MarketRepository ensureMarketRepository() =>
    maybeFindMarketRepository() ?? Get.put(MarketRepository(), permanent: true);
