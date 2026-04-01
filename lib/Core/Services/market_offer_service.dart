import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:turqappv2/Core/Services/market_notification_service.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Models/market_offer_model.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'market_offer_service_action_part.dart';
part 'market_offer_service_query_part.dart';

class MarketOfferService {
  MarketOfferService._();
  static MarketOfferService? _instance;
  static MarketOfferService? maybeFind() => _instance;

  static MarketOfferService ensure() =>
      maybeFind() ?? (_instance = MarketOfferService._());

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<String> _resolveCurrentUid() async {
    final ensured = await CurrentUserService.instance.ensureAuthReady(
      waitForAuthState: true,
      forceTokenRefresh: true,
      timeout: const Duration(seconds: 8),
    );
    return (ensured ?? CurrentUserService.instance.authUserId).trim();
  }

  static Future<void> createOffer({
    required MarketItemModel item,
    required double offerPrice,
    String message = '',
  }) =>
      _createOfferImpl(
        item: item,
        offerPrice: offerPrice,
        message: message,
      );

  static Future<List<MarketOfferModel>> fetchSentOffers(String uid) async {
    if (uid.trim().isEmpty) return const <MarketOfferModel>[];
    return _fetchSentOffersImpl(uid);
  }

  static Future<List<MarketOfferModel>> fetchReceivedOffers(String uid) async {
    if (uid.trim().isEmpty) return const <MarketOfferModel>[];
    return _fetchReceivedOffersImpl(uid);
  }

  static Future<void> respondToOffer({
    required MarketOfferModel offer,
    required String status,
  }) =>
      _respondToOfferImpl(
        offer: offer,
        status: status,
      );
}
