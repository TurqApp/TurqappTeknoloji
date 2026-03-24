import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Services/market_saved_store.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_detail_view.dart';
import 'package:turqappv2/Modules/Market/market_listing_card.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'market_saved_view_content_part.dart';
part 'market_saved_view_actions_part.dart';

class MarketSavedView extends StatefulWidget {
  const MarketSavedView({super.key});

  @override
  State<MarketSavedView> createState() => _MarketSavedViewState();
}
