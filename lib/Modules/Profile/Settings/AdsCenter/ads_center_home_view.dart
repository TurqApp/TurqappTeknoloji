import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_campaign_editor_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_campaign_list_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_center_controller.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_creative_review_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_dashboard_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_delivery_monitor_view.dart';
import 'package:turqappv2/Modules/Profile/Settings/AdsCenter/ads_preview_screen.dart';

part 'ads_center_home_view_shell_part.dart';
part 'ads_center_home_view_lifecycle_part.dart';

class AdsCenterHomeView extends StatefulWidget {
  const AdsCenterHomeView({super.key});

  @override
  State<AdsCenterHomeView> createState() => _AdsCenterHomeViewState();
}

class _AdsCenterHomeViewState extends State<AdsCenterHomeView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final AdsCenterController _controller;
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    _initLifecycle();
  }

  @override
  void dispose() {
    _disposeLifecycle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _buildPage(context);
}
