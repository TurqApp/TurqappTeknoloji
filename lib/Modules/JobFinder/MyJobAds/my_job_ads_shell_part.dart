part of 'my_job_ads.dart';

extension MyJobAdsShellPart on _MyJobAdsState {
  Widget _buildMyJobAdsBody() {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [BackButtons(text: "pasaj.job_finder.my_ads".tr)],
            ),
          ),
          PageLineBar(
            barList: [
              "pasaj.job_finder.published_tab".tr,
              "pasaj.job_finder.expired_tab".tr,
            ],
            pageName: _pageLineBarTag,
            pageController: controller.pageController,
          ),
          Expanded(child: _buildAdsPageView()),
        ],
      ),
    );
  }
}
