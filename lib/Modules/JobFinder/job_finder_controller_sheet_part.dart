part of 'job_finder_controller.dart';

extension JobFinderControllerSheetPart on JobFinderController {
  Future<void> siralaTapped() async {
    final context = Get.context;
    if (context == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(sheetContext).padding.bottom + 12,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSheetHeader(title: "pasaj.job_finder.sort_title".tr),
                buildRow(0, "pasaj.job_finder.sort_newest".tr, () {
                  short.value = 0;
                  applySorting(list);
                  Navigator.of(sheetContext).pop();
                }),
                buildRow(1, "pasaj.job_finder.sort_nearest_me".tr, () {
                  short.value = 1;
                  applySorting(list);
                  Navigator.of(sheetContext).pop();
                }),
                buildRow(2, "pasaj.job_finder.sort_most_viewed".tr, () {
                  short.value = 2;
                  applySorting(list);
                  Navigator.of(sheetContext).pop();
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> filtreTapped() async {
    final selectedType = "".obs;

    final types = [
      "Tam Zamanlı",
      "Yarı Zamanlı",
      "Part-Time",
      "Uzaktan",
      "Hibrit",
    ];

    final context = Get.context;
    if (context == null) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              12,
              20,
              MediaQuery.of(sheetContext).padding.bottom + 12,
            ),
            child: Obx(() {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSheetHeader(title: "pasaj.market.filter.title".tr),
                  Text(
                    "pasaj.job_finder.create.work_type".tr,
                    style: const TextStyle(fontFamily: "MontserratMedium"),
                  ),
                  const SizedBox(height: 8),
                  ...types.map(
                    (type) => buildFilterRow(
                      localizeJobWorkType(type),
                      selectedType.value == type,
                      () {
                        selectedType.value =
                            selectedType.value == type ? "" : type;
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () {
                      filtre.value = true;

                      final filtered = allJobs.where((job) {
                        final matchCity = isAllTurkeySelection(sehir.value) ||
                            job.city == sehir.value;
                        final normalizedSelectedType = normalizeSearchText(
                          selectedType.value,
                        );
                        final matchType = selectedType.value.isEmpty ||
                            job.calismaTuru
                                .map(normalizeSearchText)
                                .contains(normalizedSelectedType);
                        return matchCity && matchType;
                      }).toList();

                      applySorting(filtered);
                      list.value = filtered;
                      Navigator.of(sheetContext).pop();
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        "pasaj.market.filter.apply".tr,
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      filtre.value = false;
                      short.value = 0;
                      list.value = allJobs.toList();
                      applySorting(list);
                      Navigator.of(sheetContext).pop();
                    },
                    child: Center(
                      child: Text(
                        "pasaj.job_finder.clear_filters".tr,
                        style: const TextStyle(
                          color: Colors.red,
                          fontFamily: "MontserratMedium",
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  void applySorting(List<JobModel> jobs) {
    switch (short.value) {
      case 1:
        jobs.sort((a, b) => a.kacKm.compareTo(b.kacKm));
        break;
      case 2:
        jobs.sort((a, b) => b.viewCount.compareTo(a.viewCount));
        break;
      default:
        jobs.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));
    }
  }

  Widget buildFilterRow(
    String text,
    bool isSelected,
    VoidCallback onSelected,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onSelected,
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey),
              ),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.black : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black,
                fontFamily: "MontserratMedium",
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildRow(int selection, String text, VoidCallback onSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: onSelected,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.grey),
              ),
              child: Padding(
                padding: const EdgeInsets.all(3),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        short.value == selection ? Colors.black : Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratMedium",
              ),
            ),
          ],
        ),
      ),
    );
  }
}
