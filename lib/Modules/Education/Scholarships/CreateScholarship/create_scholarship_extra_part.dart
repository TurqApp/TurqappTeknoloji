part of 'create_scholarship_view.dart';

extension CreateScholarshipExtraPart on CreateScholarshipView {
  String _duplicateStatusLabel(String value) {
    switch (value) {
      case 'Alabilir':
        return 'scholarship.duplicate_status.can_receive'.tr;
      case 'Alamaz (KYK Hariç)':
        return 'scholarship.duplicate_status.cannot_receive_except_kyk'.tr;
      default:
        return value;
    }
  }

  String _repayableLabel(String value) {
    switch (value) {
      case 'Evet':
        return 'common.yes'.tr;
      case 'Hayır':
        return 'common.no'.tr;
      default:
        return value;
    }
  }

  String _targetAudienceLabel(String value) {
    switch (value) {
      case 'Nüfusa Göre':
        return 'scholarship.target.population'.tr;
      case 'İkamete Göre':
        return 'scholarship.target.residence'.tr;
      case 'Tüm Türkiye':
        return 'scholarship.target.all_turkiye'.tr;
      default:
        return value;
    }
  }

  String _educationAudienceLabel(String value) {
    switch (value) {
      case 'Hepsi':
        return 'scholarship.education.all'.tr;
      case 'Ortaokul':
        return 'scholarship.education.middle_school'.tr;
      case 'Lise':
        return 'scholarship.education.high_school'.tr;
      case 'Lisans':
        return 'scholarship.education.undergraduate'.tr;
      default:
        return value;
    }
  }

  String _degreeTypeLabel(String value) {
    switch (value) {
      case 'Ön Lisans':
        return 'scholarship.degree.associate'.tr;
      case 'Lisans':
        return 'scholarship.degree.bachelor'.tr;
      case 'Yüksek Lisans':
        return 'scholarship.degree.master'.tr;
      case 'Doktora':
        return 'scholarship.degree.phd'.tr;
      default:
        return value;
    }
  }

  Widget buildEkBilgiler(
    BuildContext context,
    CreateScholarshipController controller,
  ) {
    final containerDecoration = BoxDecoration(
      color: Colors.grey.withAlpha(20),
      borderRadius: BorderRadius.circular(12),
    );

    const inputDecoration = InputDecoration(
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: GestureDetector(
            onTap: () => controller.currentSection.value = 2,
            child: Row(
              children: [
                const Icon(CupertinoIcons.arrow_left, color: Colors.black),
                const SizedBox(width: 12),
                Text(
                  'scholarship.application_info'.tr,
                  style: TextStyles.headerTextStyle,
                ),
              ],
            ),
          ),
        ),
        Text(
          "scholarship.extra_info".tr,
          style: TextStyles.textFieldTitle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        16.ph,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "scholarship.amount_label".tr,
                    style: TextStyles.textFieldTitle,
                  ),
                  Container(
                    decoration: containerDecoration,
                    child: TextFormField(
                      cursorColor: Colors.black,
                      keyboardType: TextInputType.number,
                      decoration: inputDecoration.copyWith(
                        hintText: "scholarship.amount_hint".tr,
                      ),
                      controller: controller.tutarController,
                      onChanged: (value) => controller.tutar.value = value,
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ],
              ),
            ),
            8.pw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "scholarship.student_count_label".tr,
                    style: TextStyles.textFieldTitle,
                  ),
                  Container(
                    decoration: containerDecoration,
                    child: TextFormField(
                      cursorColor: Colors.black,
                      keyboardType: TextInputType.number,
                      decoration: inputDecoration.copyWith(
                        hintText: "scholarship.student_count_hint".tr,
                      ),
                      controller: controller.ogrenciSayisiController,
                      onChanged: (value) =>
                          controller.ogrenciSayisi.value = value,
                      onEditingComplete: () {
                        FocusScope.of(context).unfocus();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 15, color: Colors.grey.shade700),
            4.pw,
            Expanded(
              child: Text(
                'scholarship.amount_student_count_notice'.tr,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontFamily: "Montserrat",
                ),
              ),
            ),
          ],
        ),
        8.ph,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "scholarship.duplicate_status_label".tr,
                    style: TextStyles.textFieldTitle,
                  ),
                  GestureDetector(
                    onTap: () {
                      AppBottomSheet.show(
                        context: Get.context!,
                        items: const ["Alabilir", "Alamaz (KYK Hariç)"],
                        title: "scholarship.duplicate_status_label".tr,
                        selectedItem: controller.mukerrerDurumu.value,
                        itemLabelBuilder: (item) =>
                            _duplicateStatusLabel(item.toString()),
                        onSelect: (value) {
                          controller.mukerrerDurumu.value = value;
                        },
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
                              _duplicateStatusLabel(
                                controller.mukerrerDurumu.value,
                              ),
                              style: const TextStyle(color: Colors.black),
                            ),
                            const Icon(CupertinoIcons.chevron_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            8.pw,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "scholarship.repayable_label".tr,
                    style: TextStyles.textFieldTitle,
                  ),
                  GestureDetector(
                    onTap: () {
                      AppBottomSheet.show(
                        context: Get.context!,
                        items: const ["Evet", "Hayır"],
                        title: "scholarship.repayable_label".tr,
                        selectedItem: controller.geriOdemeli.value,
                        itemLabelBuilder: (item) =>
                            _repayableLabel(item.toString()),
                        onSelect: (value) {
                          controller.geriOdemeli.value = value;
                        },
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
                              _repayableLabel(controller.geriOdemeli.value),
                              style: const TextStyle(color: Colors.black),
                            ),
                            const Icon(CupertinoIcons.chevron_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        16.ph,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "scholarship.target_audience_label".tr,
                    style: TextStyles.textFieldTitle,
                  ),
                  GestureDetector(
                    onTap: () {
                      AppBottomSheet.show(
                        context: Get.context!,
                        items: const [
                          "Nüfusa Göre",
                          "İkamete Göre",
                          "Tüm Türkiye",
                        ],
                        title: "scholarship.target_audience_label".tr,
                        selectedItem: controller.hedefKitle.value,
                        itemLabelBuilder: (item) =>
                            _targetAudienceLabel(item.toString()),
                        onSelect: (value) {
                          controller.hedefKitle.value = value;
                          if (value == "Tüm Türkiye") {
                            controller.sehirler.clear();
                            controller.ilceler.clear();
                          }
                          if (value != "Lisans") {
                            controller.universiteler.clear();
                          }
                        },
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
                              controller.hedefKitle.value.isEmpty
                                  ? "scholarship.target_audience_label".tr
                                  : _targetAudienceLabel(
                                      controller.hedefKitle.value,
                                    ),
                              style: const TextStyle(color: Colors.black),
                            ),
                            const Icon(CupertinoIcons.chevron_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        16.ph,
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "scholarship.education_audience_label".tr,
                    style: TextStyles.textFieldTitle,
                  ),
                  GestureDetector(
                    onTap: () {
                      AppBottomSheet.show(
                        context: Get.context!,
                        items: const [
                          "Hepsi",
                          "Ortaokul",
                          "Lise",
                          "Lisans",
                        ],
                        title: "scholarship.education_audience_label".tr,
                        selectedItem: controller.egitimKitlesi.value,
                        itemLabelBuilder: (item) =>
                            _educationAudienceLabel(item.toString()),
                        onSelect: (value) {
                          controller.egitimKitlesi.value = value;
                          if (value != "Lisans") {
                            controller.lisansTuru.clear();
                            controller.universiteler.clear();
                          }
                        },
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
                              controller.egitimKitlesi.value.isEmpty
                                  ? "scholarship.education_audience_label".tr
                                  : _educationAudienceLabel(
                                      controller.egitimKitlesi.value,
                                    ),
                              style: const TextStyle(color: Colors.black),
                            ),
                            const Icon(CupertinoIcons.chevron_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Obx(
              () => controller.egitimKitlesi.value == "Hepsi" ||
                      controller.egitimKitlesi.value == "Ortaokul" ||
                      controller.egitimKitlesi.value == "Lise"
                  ? const SizedBox.shrink()
                  : 8.pw,
            ),
            Obx(() {
              if (controller.egitimKitlesi.value == "Lisans") {
                return Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "scholarship.degree_type_label".tr,
                        style: TextStyles.textFieldTitle,
                      ),
                      GestureDetector(
                        onTap: () {
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
                              title: "scholarship.degree_type_select".tr,
                              items: const [
                                "Ön Lisans",
                                "Lisans",
                                "Yüksek Lisans",
                                "Doktora",
                              ],
                              selectedItems: controller.lisansTuru,
                              itemLabelBuilder: _degreeTypeLabel,
                              onConfirm: (selected) {
                                controller.lisansTuru.assignAll(selected);
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
                                  controller.lisansTuru.isEmpty
                                      ? "scholarship.degree_type_select".tr
                                      : controller.lisansTuru.length > 1
                                          ? 'common.selected_count'
                                              .trParams({
                                              'count': controller
                                                  .lisansTuru.length
                                                  .toString(),
                                            })
                                          : _degreeTypeLabel(
                                              controller.lisansTuru.first,
                                            ),
                                  style: const TextStyle(color: Colors.black),
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
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        16.ph,
        Obx(() {
          if (controller.hedefKitle.value == "Nüfusa Göre" ||
              controller.hedefKitle.value == "İkamete Göre") {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Country Selection
                Text(
                  "scholarship.country_label".tr,
                  style: TextStyles.textFieldTitle,
                ),
                GestureDetector(
                  onTap: () {
                    ListBottomSheet.show(
                      context: context,
                      items: ["Türkiye"], // Add more countries if needed
                      title: "scholarship.select_country".tr,
                      selectedItem: controller.ulke.value.isEmpty
                          ? null
                          : controller.ulke.value,
                      onSelect: (value) {
                        controller.ulke.value = value;
                        // Clear cities and districts if country changes
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
                // City and District Selection
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("common.city".tr,
                              style: TextStyles.textFieldTitle),
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
                                  controller.sehirler
                                      .clear(); // Single selection
                                  controller.sehirler.add(selected);
                                  // Clear districts and universities that are not valid for the selected city
                                  final validIlceler = controller.ilceler
                                      .where((ilce) => controller
                                          .getDistrictsForSelectedCities()
                                          .contains(ilce))
                                      .toList();
                                  controller.ilceler.assignAll(validIlceler);
                                  final validUniversiteler = controller
                                      .universiteler
                                      .where((uni) =>
                                          uni == 'Tüm Üniversiteler' ||
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
                                    const Icon(CupertinoIcons.chevron_down,
                                        size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (controller.egitimKitlesi.value != "Lisans") ...[
                      8.pw,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("common.district".tr,
                                style: TextStyles.textFieldTitle),
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
                                    controller.ilceler
                                        .clear(); // Single selection
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
                                            color: Colors.black),
                                      ),
                                      const Icon(CupertinoIcons.chevron_down,
                                          size: 20),
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
          () => controller.hedefKitle.value == "Nüfusa Göre" ||
                  controller.hedefKitle.value == "İkamete Göre"
              ? const SizedBox(height: 16)
              : const SizedBox.shrink(),
        ),
        Obx(() {
          if (controller.egitimKitlesi.value == "Lisans") {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "scholarship.universities_label".tr,
                  style: TextStyles.textFieldTitle,
                ),
                GestureDetector(
                  onTap: () {
                    if (controller.hedefKitle.value != "Tüm Türkiye" &&
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
                                    "Tüm Üniversiteler",
                                  )
                                    ? controller.universiteler.join(", ")
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
                              label: Text(uni),
                              onDeleted: () {
                                if (uni == 'Tüm Üniversiteler') {
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
        const SizedBox(height: 20),
        Row(
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
                child: Text('common.back'.tr,
                    style: TextStyles.medium15Black),
              ),
            ),
            GestureDetector(
              onTap: () {
                if (controller.tutar.value.isEmpty ||
                    controller.ogrenciSayisi.value.isEmpty ||
                    controller.mukerrerDurumu.value.isEmpty ||
                    controller.geriOdemeli.value.isEmpty ||
                    controller.hedefKitle.value.isEmpty ||
                    controller.egitimKitlesi.value.isEmpty ||
                    (controller.egitimKitlesi.value == "Lisans" &&
                        controller.lisansTuru.isEmpty) ||
                    ((controller.hedefKitle.value == "Nüfusa Göre" ||
                            controller.hedefKitle.value == "İkamete Göre") &&
                        controller
                            .ulke.value.isEmpty) || // Add country validation
                    ((controller.hedefKitle.value == "Nüfusa Göre" ||
                            controller.hedefKitle.value == "İkamete Göre") &&
                        controller.sehirler.isEmpty) ||
                    (controller.egitimKitlesi.value == "Lisans" &&
                        controller.hedefKitle.value != "Tüm Türkiye" &&
                        controller.sehirler.isEmpty &&
                        controller.universiteler.isEmpty)) {
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
                child: Text('common.continue'.tr,
                    style: TextStyles.medium15white),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
