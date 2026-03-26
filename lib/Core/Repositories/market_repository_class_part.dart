part of 'market_repository.dart';

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
