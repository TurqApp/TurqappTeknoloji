part of 'market_repository_library.dart';

abstract class _MarketRepositoryBase extends GetxService {
  _MarketRepositoryBase({FirebaseFirestore? firestore})
      : _state = _MarketRepositoryState(firestore: firestore);

  final _MarketRepositoryState _state;

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((prefs) => _state.prefs = prefs);
  }
}
