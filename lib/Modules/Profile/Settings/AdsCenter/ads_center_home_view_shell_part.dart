part of 'ads_center_home_view.dart';

extension AdsCenterHomeViewShellPart on _AdsCenterHomeViewState {
  Widget _buildPage(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() {
        if (_controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!_controller.canAccess.value) {
          return _buildAdminOnlyState();
        }

        final error = _controller.errorText.value;
        if (error != null && error.isNotEmpty) {
          return _buildErrorState(error);
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
    );
  }

  Widget _buildAdminOnlyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'ads_center.admin_only'.tr,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'MontserratMedium',
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 32),
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
}
