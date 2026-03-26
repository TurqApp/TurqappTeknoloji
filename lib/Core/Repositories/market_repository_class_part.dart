part of 'market_repository_library.dart';

class MarketRepository extends _MarketRepositoryBase {
  MarketRepository({super.firestore});
  static const Duration _ttl = Duration(hours: 3);
  static const String _prefsPrefix = 'market_repository_v1';
}
