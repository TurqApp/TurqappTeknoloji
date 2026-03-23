part of 'ads_center_home_view.dart';

extension AdsCenterHomeViewTabsPart on _AdsCenterHomeViewState {
  Widget _buildTabs() {
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
  }
}
