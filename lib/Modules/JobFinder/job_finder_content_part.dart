part of 'job_finder.dart';

extension JobFinderContentPart on JobFinder {
  Widget _kesfetTab(BuildContext context) {
    return Obx(() {
      if (!controller.listingSelectionReady.value) {
        return const Center(child: CupertinoActivityIndicator());
      }
      if (controller.isLoading.value && controller.list.isEmpty) {
        return Column(
          children: [
            _kesfetHeader(isSearching: false, context: context),
            const Expanded(
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ],
        );
      }
      if (controller.list.isEmpty) {
        return Column(
          children: [
            _kesfetHeader(isSearching: false, context: context),
            const SizedBox(height: 50),
            EmptyRow(text: "common.no_results".tr),
          ],
        );
      }

      final query = controller.search.text.trim();
      final isSearching = query.length >= 2;
      final tumTurkiye =
          controller.isAllTurkeySelection(controller.sehir.value);

      final dataList = isSearching
          ? controller.aramaSonucu
          : (tumTurkiye
              ? controller.list
              : controller.list
                  .where(
                    (e) => e.city.toString().contains(controller.sehir.value),
                  )
                  .toList());

      if (controller.listingSelection.value == 0) {
        if (dataList.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kesfetHeader(isSearching: isSearching, context: context),
              EmptyRow(
                text: isSearching
                    ? "pasaj.job_finder.no_search_result".tr
                    : "pasaj.job_finder.no_city_listing".tr,
              ),
            ],
          );
        }
        return ListView(
          children: [
            _kesfetHeader(isSearching: isSearching, context: context),
            ...PasajListingAdLayout.buildListChildren(
              items: dataList,
              itemBuilder: (item, index) => JobContent(
                model: item,
                isGrid: false,
              ),
              adBuilder: (slot) => Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                child: AdmobKare(
                  key: ValueKey('job-list-ad-$slot'),
                ),
              ),
            ),
          ],
        );
      }

      if (dataList.isEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _kesfetHeader(isSearching: isSearching, context: context),
            EmptyRow(
              text: isSearching
                  ? "pasaj.job_finder.no_search_result".tr
                  : "pasaj.job_finder.no_city_listing".tr,
            ),
          ],
        );
      }

      return SingleChildScrollView(
        child: Column(
          children: [
            _kesfetHeader(isSearching: isSearching, context: context),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Column(
                children: PasajListingAdLayout.buildTwoColumnGridChildren(
                  items: dataList,
                  horizontalSpacing: 8,
                  rowSpacing: 8,
                  itemBuilder: (item, index) =>
                      JobContent(model: item, isGrid: true),
                  adBuilder: (slot) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: AdmobKare(
                      key: ValueKey('job-grid-ad-$slot'),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
