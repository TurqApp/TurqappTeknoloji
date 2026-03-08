import 'package:flutter/material.dart';
import 'package:get/get.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _controller = Get.isRegistered<AdsCenterController>()
        ? Get.find<AdsCenterController>()
        : Get.put(AdsCenterController());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Reklam Merkezi',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'MontserratBold',
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.black,
          indicatorColor: Colors.black,
          labelStyle: const TextStyle(
            fontFamily: 'MontserratMedium',
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'Kampanyalar'),
            Tab(text: 'Editor'),
            Tab(text: 'Kreatif'),
            Tab(text: 'Monitor'),
            Tab(text: 'Preview'),
          ],
        ),
      ),
      body: Obx(() {
        if (_controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!_controller.canAccess.value) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Bu alan sadece admin erişimine açıktır.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'MontserratMedium',
                  fontSize: 14,
                ),
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
