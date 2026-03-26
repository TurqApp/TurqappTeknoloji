part of 'market_repository.dart';

class MarketRepository extends GetxService {
  MarketRepository({FirebaseFirestore? firestore})
      : _state = _MarketRepositoryState(firestore: firestore);

  final _MarketRepositoryState _state;
  static const Duration _ttl = Duration(hours: 3);
  static const String _prefsPrefix = 'market_repository_v1';

  static MarketRepository? maybeFind() => Get.isRegistered<MarketRepository>()
      ? Get.find<MarketRepository>()
      : null;

  static MarketRepository ensure() =>
      maybeFind() ?? Get.put(MarketRepository(), permanent: true);

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _prefs = prefs);
  }
}
