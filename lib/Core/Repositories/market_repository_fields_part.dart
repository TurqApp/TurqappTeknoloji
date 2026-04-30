part of 'market_repository_library.dart';

class _MarketRepositoryState {
  _MarketRepositoryState({FirebaseFirestore? firestore})
      : firestore = firestore ?? AppFirestore.instance;

  final FirebaseFirestore firestore;
  final Map<String, _TimedMarketItems> memory = <String, _TimedMarketItems>{};
  SharedPreferences? prefs;
}

extension MarketRepositoryFieldsPart on MarketRepository {
  FirebaseFirestore get _firestore => _state.firestore;
  Map<String, _TimedMarketItems> get _memory => _state.memory;
  SharedPreferences? get _prefs => _state.prefs;
  set _prefs(SharedPreferences? value) => _state.prefs = value;
  CollectionReference<Map<String, dynamic>> get _itemsRef =>
      _firestore.collection('marketStore');
}
