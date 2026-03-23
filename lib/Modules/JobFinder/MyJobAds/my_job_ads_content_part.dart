part of 'my_job_ads.dart';

extension MyJobAdsContentPart on _MyJobAdsState {
  Widget _buildAdsPageView() {
    return PageView(
      controller: controller.pageController,
      onPageChanged: (value) {
        syncPageLineBarSelection(_pageLineBarTag, value);
      },
      children: [_buildActiveAdsPage(), _buildDeactiveAdsPage()],
    );
  }

  Widget _buildActiveAdsPage() {
    return Obx(() {
      if (controller.isLoadingActive.value && controller.active.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.black),
        );
      }

      if (controller.active.isEmpty) {
        return EmptyRow(text: "pasaj.job_finder.no_my_ads".tr);
      }

      return ListView.builder(
        itemCount: controller.active.length,
        itemBuilder: (context, index) {
          final model = controller.active[index];
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 7 : 0),
            child: JobContent(
              key: ValueKey('myjob-active-${model.docID}'),
              model: model,
              isGrid: false,
            ),
          );
        },
      );
    });
  }

  Widget _buildDeactiveAdsPage() {
    return Obx(() {
      if (controller.isLoadingDeactive.value && controller.deactive.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Colors.black),
        );
      }

      if (controller.deactive.isEmpty) {
        return EmptyRow(text: "pasaj.job_finder.no_my_ads".tr);
      }

      return ListView.builder(
        itemCount: controller.deactive.length,
        itemBuilder: (context, index) {
          final model = controller.deactive[index];
          return Padding(
            padding: EdgeInsets.only(top: index == 0 ? 7 : 0),
            child: JobContent(
              key: ValueKey('myjob-ended-${model.docID}'),
              model: model,
              isGrid: false,
            ),
          );
        },
      );
    });
  }
}
