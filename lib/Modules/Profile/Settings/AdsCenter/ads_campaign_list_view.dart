import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_campaign_editor_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

part 'ads_campaign_list_view_content_part.dart';
part 'ads_campaign_list_view_tile_part.dart';

class AdsCampaignListView extends StatelessWidget {
  const AdsCampaignListView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdsCenterController.ensure();
    return _buildPage(controller);
  }
}
