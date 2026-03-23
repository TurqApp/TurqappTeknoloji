import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Utils/text_normalization_utils.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';

part 'ads_delivery_monitor_view_content_part.dart';
part 'ads_delivery_monitor_view_card_part.dart';

class AdsDeliveryMonitorView extends StatelessWidget {
  const AdsDeliveryMonitorView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AdsCenterController.ensure();
    return _buildPage(controller);
  }
}
