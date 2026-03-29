part of 'job_finder.dart';

extension JobFinderHeaderPart on JobFinder {
  Widget _kesfetHeader({
    required bool isSearching,
    required BuildContext context,
  }) {
    return Column(
      children: [
        EducationSlider(
          sliderId: 'is_bul',
          imageList: [AppAssets.job1, AppAssets.job2, AppAssets.job3],
        ),
        if (!embedded) ...[
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TurqSearchBar(
              controller: controller.search,
              hintText: "pasaj.job_finder.search_hint".tr,
            ),
          ),
        ],
        if (!isSearching && !embedded)
          Obx(() {
            return Padding(
              padding: const EdgeInsets.only(
                left: 15,
                right: 15,
                top: 15,
                bottom: 7,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      "pasaj.job_finder.nearby_listings".tr,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.siralaTapped(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_up_arrow_down,
                          size: 14,
                          color: controller.short.value != 0
                              ? Colors.pinkAccent
                              : Colors.black,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          controller.short.value == 0
                              ? "pasaj.common.sort".tr
                              : controller.short.value == 1
                                  ? "pasaj.job_finder.sort_high_salary".tr
                                  : controller.short.value == 2
                                      ? "pasaj.job_finder.sort_low_salary".tr
                                      : "pasaj.job_finder.sort_nearest".tr,
                          style: TextStyle(
                            color: controller.short.value != 0
                                ? Colors.pinkAccent
                                : Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 7),
                  AppHeaderActionButton(
                    size: 36,
                    onTap: () => controller.filtreTapped(),
                    child: Icon(
                      Icons.filter_alt_outlined,
                      color: controller.filtre.value
                          ? Colors.pinkAccent
                          : Colors.black,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AppHeaderActionButton(
                    size: 36,
                    onTap: controller.toggleListingSelection,
                    child: Icon(
                      controller.listingSelection.value == 0
                          ? CupertinoIcons.list_bullet
                          : CupertinoIcons.square_grid_2x2,
                      color: Colors.black,
                      size: 18,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
