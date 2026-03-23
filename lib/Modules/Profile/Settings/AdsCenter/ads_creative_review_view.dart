import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Models/Ads/ads_models.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

part 'ads_creative_review_view_content_part.dart';

class AdsCreativeReviewView extends StatelessWidget {
  const AdsCreativeReviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdsCenterController.ensure();
    return _buildPage(context, controller);
  }
}
