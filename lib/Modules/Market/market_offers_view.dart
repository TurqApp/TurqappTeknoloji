import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/market_offer_service.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_offer_model.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
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
  late final String uid;
  late Future<List<MarketOfferModel>> sentFuture;
  late Future<List<MarketOfferModel>> receivedFuture;
  final Set<String> _processingIds = <String>{};

  @override
  void initState() {
    super.initState();
    uid = CurrentUserService.instance.effectiveUserId;
    _reload();
  }

  void _reload() {
    sentFuture = MarketOfferService.fetchSentOffers(uid);
    receivedFuture = MarketOfferService.fetchReceivedOffers(uid);
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);

  void _updateViewState(VoidCallback updater) {
    if (!mounted) return;
    setState(updater);
  }
}
