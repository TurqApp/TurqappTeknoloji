import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/Widgets/cache_first_network_image.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/market_detail_navigation_service.dart';
import 'package:turqappv2/Core/Services/market_offer_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_offer_model.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'market_offers_view_actions_part.dart';
part 'market_offers_view_content_part.dart';

class MarketOffersView extends StatefulWidget {
  const MarketOffersView({super.key});

  @override
  State<MarketOffersView> createState() => _MarketOffersViewState();
}

class _MarketOffersViewState extends State<MarketOffersView> {
  final MarketRepository _repository = ensureMarketRepository();
  late Future<List<MarketOfferModel>> sentFuture;
  late Future<List<MarketOfferModel>> receivedFuture;
  final Set<String> _processingIds = <String>{};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    sentFuture = _loadSentOffers();
    receivedFuture = _loadReceivedOffers();
  }

  Future<String> _resolveCurrentUid() async {
    final ensured = await CurrentUserService.instance.ensureAuthReady(
      waitForAuthState: true,
      forceTokenRefresh: true,
      timeout: const Duration(seconds: 8),
    );
    return (ensured ?? CurrentUserService.instance.authUserId).trim();
  }

  Future<List<MarketOfferModel>> _loadSentOffers() async {
    final uid = await _resolveCurrentUid();
    if (uid.isEmpty) return const <MarketOfferModel>[];
    return MarketOfferService.fetchSentOffers(uid);
  }

  Future<List<MarketOfferModel>> _loadReceivedOffers() async {
    final uid = await _resolveCurrentUid();
    if (uid.isEmpty) return const <MarketOfferModel>[];
    return MarketOfferService.fetchReceivedOffers(uid);
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }
}
