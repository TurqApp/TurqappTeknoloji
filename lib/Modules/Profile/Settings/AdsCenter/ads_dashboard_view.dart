import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Services/Ads/ads_feature_flags_service.dart';
import 'package:turqappv2/Models/Ads/ad_feature_flags.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

part 'ads_dashboard_view_content_part.dart';

class AdsDashboardView extends StatelessWidget {
  const AdsDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdsCenterController.ensure();
    final flagsService = AdsFeatureFlagsService.to;
    return _buildPage(
      controller: controller,
      flagsService: flagsService,
    );
  }
}
