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
    _tabController = TabController(length: 6, vsync: this);
    final existingController = AdsCenterController.maybeFind();
    if (existingController != null) {
      _controller = existingController;
    } else {
      _controller = AdsCenterController.ensure();
      _ownsController = true;
    }
  }

  @override
  void dispose() {
    if (_ownsController &&
        identical(AdsCenterController.maybeFind(), _controller)) {
      Get.delete<AdsCenterController>(force: true);
    }
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(icon: Icons.arrow_back),
        title: AppPageTitle('ads_center.title'.tr, fontSize: 18),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.black,
          indicatorColor: Colors.black,
          labelStyle: const TextStyle(
            fontFamily: 'MontserratMedium',
            fontSize: 13,
          ),
          tabs: [
            Tab(text: 'ads_center.tab_dashboard'.tr),
            Tab(text: 'ads_center.tab_campaigns'.tr),
            Tab(text: 'ads_center.tab_editor'.tr),
            Tab(text: 'ads_center.tab_creatives'.tr),
            Tab(text: 'ads_center.tab_monitor'.tr),
            Tab(text: 'ads_center.tab_preview'.tr),
          ],
        ),
      ),
      body: Obx(() {
        if (_controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!_controller.canAccess.value) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'ads_center.admin_only'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 14,
                ),
              ),
            ),
          );
        }

        final error = _controller.errorText.value;
        if (error != null && error.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.orange, size: 32),
                  const SizedBox(height: 10),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'MontserratMedium',
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _controller.refreshAll,
                    child: Text('common.retry'.tr),
                  ),
                ],
              ),
            ),
          );
        }

        return TabBarView(
          controller: _tabController,
          children: const [
            AdsDashboardView(),
            AdsCampaignListView(),
            AdsCampaignEditorView(),
            AdsCreativeReviewView(),
            AdsDeliveryMonitorView(),
            AdsPreviewScreen(),
          ],
        );
      }),
    );
  }
}
