part of 'ads_center_home_view.dart';

extension AdsCenterHomeViewAppBarPart on _AdsCenterHomeViewState {
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
}
