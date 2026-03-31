import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Ads/admob_kare.dart';
import 'package:turqappv2/Core/BottomSheets/list_bottom_sheet.dart';
import 'package:turqappv2/Core/Services/Ads/admob_banner_warmup_service.dart';
import 'package:turqappv2/Core/Services/integration_test_keys.dart';
import 'package:turqappv2/Core/Services/market_contact_service.dart';
import 'package:turqappv2/Core/Services/market_share_service.dart';
import 'package:turqappv2/Core/Services/turq_image_cache_manager.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/cache_first_network_image.dart';
import 'package:turqappv2/Core/Widgets/pasaj_card_styles.dart';
import 'package:turqappv2/Core/Widgets/pasaj_grid_card.dart';
import 'package:turqappv2/Core/Widgets/pasaj_list_card_metrics.dart';
import 'package:turqappv2/Core/Widgets/pasaj_listing_ad_layout.dart';
import 'package:turqappv2/Core/Slider/education_slider.dart';
import 'package:turqappv2/Models/market_item_model.dart';
import 'package:turqappv2/Modules/Market/market_controller.dart';
import 'package:turqappv2/Modules/Market/market_listing_card.dart';
import 'package:turqappv2/Modules/Market/market_offer_utils.dart';
import 'package:turqappv2/Themes/app_icons.dart';
import 'package:turqappv2/Themes/app_assets.dart';

part 'market_view_filters_part.dart';
part 'market_view_cards_part.dart';
part 'market_view_style_part.dart';
part 'market_view_shell_part.dart';
part 'market_view_shell_content_part.dart';
part 'market_view_media_part.dart';

class MarketView extends StatelessWidget {
  MarketView({
    super.key,
    this.embedded = false,
    this.showEmbeddedControls = true,
    MarketController? controller,
  }) : controller = controller ?? ensureMarketController();

  final bool embedded;
  final bool showEmbeddedControls;
  static const MarketContactService _contactService = MarketContactService();
  static bool _bannerWarmupTriggered = false;
  final MarketController controller;

  @override
  Widget build(BuildContext context) {
    controller.primePrimarySurfaceOnce();
    return _buildView(context);
  }
}
