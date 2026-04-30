import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/Services/market_detail_navigation_service.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/Repositories/market_repository.dart';
import 'package:turqappv2/Core/Repositories/market_snapshot_repository.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/app_state_view.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';
import 'package:turqappv2/Services/current_user_service.dart';
import 'package:turqappv2/Themes/app_icons.dart';

part 'market_my_items_view_content_part.dart';
part 'market_my_items_view_actions_part.dart';

class MarketMyItemsView extends StatefulWidget {
  const MarketMyItemsView({super.key});

  @override
  State<MarketMyItemsView> createState() => _MarketMyItemsViewState();
}
