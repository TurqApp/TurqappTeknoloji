part of 'create_scholarship_view.dart';

extension CreateScholarshipExtraTargetingPart on _CreateScholarshipViewState {
  Widget _buildTargetingSection(
    BuildContext context,
    CreateScholarshipController controller,
    BoxDecoration containerDecoration,
  ) {
    return Column(
      children: [
        Obx(() {
          if (controller.hedefKitle.value == targetAudiencePopulationValue ||
              controller.hedefKitle.value == targetAudienceResidenceValue) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "scholarship.country_label".tr,
                  style: TextStyles.textFieldTitle,
                ),
                GestureDetector(
                  onTap: () {
                    ListBottomSheet.show(
                      context: context,
                      items: [controller.turkeyValue],
                      title: "scholarship.select_country".tr,
                      selectedItem: controller.ulke.value.isEmpty
                          ? null
                          : controller.ulke.value,
                      itemLabelBuilder: (item) {
                        final value = item.toString();
                        if (value == controller.turkeyValue) {
                          return 'common.country_turkey'.tr;
                        }
                        return value;
                      },
                      searchTextBuilder: (item) {
                        final value = item.toString();
                        if (value == controller.turkeyValue) {
                          return 'common.country_turkey'.tr;
                        }
                        return value;
                      },
                      onSelect: (value) {
                        controller.ulke.value = value;
                        controller.sehirler.clear();
                        controller.ilceler.clear();
                        controller.universiteler.clear();
                      },
                      isSearchable: false,
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    alignment: Alignment.centerLeft,
                    decoration: containerDecoration,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.ulke.value.isEmpty
                                ? "scholarship.select_country".tr
                                : controller.ulke.value,
                            style: const TextStyle(color: Colors.black),
                          ),
                          const Icon(CupertinoIcons.chevron_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "common.city".tr,
                            style: TextStyles.textFieldTitle,
                          ),
                          GestureDetector(
                            onTap: () {
                              if (controller.ulke.value.isEmpty) {
                                AppSnackbar(
                                  'common.error'.tr,
                                  'scholarship.select_country_first'.tr,
                                );
                                return;
                              }
                              ListBottomSheet.show(
                                context: context,
                                items: controller.iller,
                                title: "common.select_city".tr,
                                selectedItem: controller.sehirler.isNotEmpty
                                    ? controller.sehirler.first
                                    : null,
                                onSelect: (selected) {
                                  controller.sehirler.clear();
                                  controller.sehirler.add(selected);
                                  final validIlceler = controller.ilceler
                                      .where((ilce) => controller
                                          .getDistrictsForSelectedCities()
                                          .contains(ilce))
                                      .toList();
                                  controller.ilceler.assignAll(validIlceler);
                                  final validUniversiteler = controller
                                      .universiteler
                                      .where((uni) =>
                                          uni == allUniversitiesValue ||
                                          controller
                                              .getUniversitiesForSelectedCities()
                                              .contains(uni))
                                      .toList();
                                  controller.universiteler
                                      .assignAll(validUniversiteler);
                                },
                                isSearchable: true,
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              alignment: Alignment.centerLeft,
                              decoration: containerDecoration,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Obx(
                                () => Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      controller.sehirler.isEmpty
                                          ? "common.select_city".tr
                                          : controller.sehirler.first,
                                      style:
                                          const TextStyle(color: Colors.black),
                                    ),
                                    const Icon(
                                      CupertinoIcons.chevron_down,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.egitimKitlesi.value !=
                        educationAudienceUndergraduateValue) ...[
                      8.pw,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "common.district".tr,
                              style: TextStyles.textFieldTitle,
                            ),
                            GestureDetector(
                              onTap: () {
                                if (controller.sehirler.isEmpty) {
                                  AppSnackbar(
                                    'common.error'.tr,
                                    'scholarship.select_city_first'.tr,
                                  );
                                  return;
                                }
                                ListBottomSheet.show(
                                  context: context,
                                  items: controller
                                      .getDistrictsForSelectedCities(),
                                  title: "common.select_district".tr,
                                  selectedItem: controller.ilceler.isNotEmpty
                                      ? controller.ilceler.first
                                      : null,
                                  onSelect: (selected) {
                                    controller.ilceler.clear();
                                    controller.ilceler.add(selected);
                                  },
                                  isSearchable: true,
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                alignment: Alignment.centerLeft,
                                decoration: containerDecoration,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Obx(
                                  () => Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        controller.ilceler.isEmpty
                                            ? "common.select_district".tr
                                            : controller.ilceler.first,
                                        style: const TextStyle(
                                          color: Colors.black,
                                        ),
                                      ),
                                      const Icon(
                                        CupertinoIcons.chevron_down,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
        Obx(
          () => controller.hedefKitle.value == targetAudiencePopulationValue ||
                  controller.hedefKitle.value == targetAudienceResidenceValue
              ? const SizedBox(height: 16)
              : const SizedBox.shrink(),
        ),
        Obx(() {
          if (controller.egitimKitlesi.value ==
              educationAudienceUndergraduateValue) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "scholarship.universities_label".tr,
                  style: TextStyles.textFieldTitle,
                ),
                GestureDetector(
                  onTap: () {
                    if (controller.hedefKitle.value !=
                            targetAudienceAllTurkeyValue &&
                        controller.sehirler.isEmpty) {
                      AppSnackbar(
                        'common.error'.tr,
                        'scholarship.select_city_first'.tr,
                      );
                      return;
                    }
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.white,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (context) => MultiSelectBottomSheet2(
                        title: "scholarship.select_university".tr,
                        items: controller.getUniversitiesForSelectedCities(),
                        selectedItems: controller.universiteler,
                        itemLabelBuilder: controller.universityLabel,
                        onConfirm: (selected) {
                          controller.universiteler.assignAll(selected);
                        },
                      ),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    alignment: Alignment.centerLeft,
                    decoration: containerDecoration,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Obx(
                      () => Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            controller.universiteler.isEmpty
                                ? "scholarship.select_university".tr
                                : controller.universiteler.contains(
                                    allUniversitiesValue,
                                  )
                                    ? controller.universityLabel(
                                        allUniversitiesValue,
                                      )
                                    : 'common.selected_count'.trParams({
                                        'count': controller.universiteler.length
                                            .toString(),
                                      }),
                            style: const TextStyle(color: Colors.black),
                          ),
                          const Icon(CupertinoIcons.chevron_down, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Obx(() {
                  if (controller.universiteler.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "scholarship.selected_universities".tr,
                          style: TextStyles.textFieldTitle.copyWith(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: controller.universiteler.map((uni) {
                            return Chip(
                              backgroundColor: Colors.grey.shade200,
                              label: Text(controller.universityLabel(uni)),
                              onDeleted: () {
                                if (uni == allUniversitiesValue) {
                                  controller.universiteler.clear();
                                } else {
                                  controller.universiteler.remove(uni);
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildExtraSectionActions(CreateScholarshipController controller) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () {
            controller.currentSection.value = 2;
          },
          child: Container(
            height: 40,
            width: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(100),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('common.back'.tr, style: TextStyles.medium15Black),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (!_canContinueFromExtraSection(controller)) {
              AppSnackbar(
                'common.error'.tr,
                'common.fill_all_fields'.tr,
                backgroundColor: Colors.red.withValues(alpha: 0.7),
              );
              return;
            }
            controller.currentSection.value = 4;
          },
          child: Container(
            height: 40,
            width: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('common.continue'.tr, style: TextStyles.medium15white),
          ),
        ),
      ],
    );
  }

  bool _canContinueFromExtraSection(CreateScholarshipController controller) {
    return controller.tutar.value.isNotEmpty &&
        controller.ogrenciSayisi.value.isNotEmpty &&
        controller.mukerrerDurumu.value.isNotEmpty &&
        controller.geriOdemeli.value.isNotEmpty &&
        controller.hedefKitle.value.isNotEmpty &&
        controller.egitimKitlesi.value.isNotEmpty &&
        (controller.egitimKitlesi.value !=
                educationAudienceUndergraduateValue ||
            controller.lisansTuru.isNotEmpty) &&
        !_requiresCountryWithoutSelection(controller) &&
        !_requiresCityWithoutSelection(controller) &&
        !_requiresUniversityWithoutSelection(controller);
  }

  bool _requiresCountryWithoutSelection(
    CreateScholarshipController controller,
  ) {
    return _usesLocationAudience(controller) && controller.ulke.value.isEmpty;
  }

  bool _requiresCityWithoutSelection(CreateScholarshipController controller) {
    return _usesLocationAudience(controller) && controller.sehirler.isEmpty;
  }

  bool _requiresUniversityWithoutSelection(
    CreateScholarshipController controller,
  ) {
    return controller.egitimKitlesi.value ==
            educationAudienceUndergraduateValue &&
        controller.hedefKitle.value != targetAudienceAllTurkeyValue &&
        controller.sehirler.isEmpty &&
        controller.universiteler.isEmpty;
  }

  bool _usesLocationAudience(CreateScholarshipController controller) {
    return controller.hedefKitle.value == targetAudiencePopulationValue ||
        controller.hedefKitle.value == targetAudienceResidenceValue;
  }
}
