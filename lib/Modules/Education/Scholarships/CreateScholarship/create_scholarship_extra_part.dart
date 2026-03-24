part of 'create_scholarship_view.dart';

extension CreateScholarshipExtraPart on _CreateScholarshipViewState {
  String _duplicateStatusLabel(String value) {
    switch (value) {
      case CreateScholarshipController.duplicateStatusCanReceiveValue:
        return 'scholarship.duplicate_status.can_receive'.tr;
      case CreateScholarshipController
            .duplicateStatusCannotReceiveExceptKykValue:
        return 'scholarship.duplicate_status.cannot_receive_except_kyk'.tr;
      default:
        return value;
    }
  }

  String _repayableLabel(String value) {
    switch (value) {
      case CreateScholarshipController.repayableYesValue:
        return 'common.yes'.tr;
      case CreateScholarshipController.repayableNoValue:
        return 'common.no'.tr;
      default:
        return value;
    }
  }

  String _targetAudienceLabel(String value) {
    switch (value) {
      case CreateScholarshipController.targetAudiencePopulationValue:
        return 'scholarship.target.population'.tr;
      case CreateScholarshipController.targetAudienceResidenceValue:
        return 'scholarship.target.residence'.tr;
      case CreateScholarshipController.targetAudienceAllTurkeyValue:
        return 'scholarship.target.all_turkiye'.tr;
      default:
        return value;
    }
  }

  String _educationAudienceLabel(String value) {
    switch (value) {
      case CreateScholarshipController.educationAudienceAllValue:
        return 'scholarship.education.all'.tr;
      case CreateScholarshipController.educationAudienceMiddleSchoolValue:
        return 'scholarship.education.middle_school'.tr;
      case CreateScholarshipController.educationAudienceHighSchoolValue:
        return 'scholarship.education.high_school'.tr;
      case CreateScholarshipController.educationAudienceUndergraduateValue:
        return 'scholarship.education.undergraduate'.tr;
      default:
        return value;
    }
  }

  String _degreeTypeLabel(String value) {
    switch (value) {
      case CreateScholarshipController.degreeAssociateValue:
        return 'scholarship.degree.associate'.tr;
      case CreateScholarshipController.degreeBachelorValue:
        return 'scholarship.degree.bachelor'.tr;
      case CreateScholarshipController.degreeMasterValue:
        return 'scholarship.degree.master'.tr;
      case CreateScholarshipController.degreePhdValue:
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
          child: Row(
            children: [
              AppBackButton(
                onTap: () => controller.currentSection.value = 2,
                icon: CupertinoIcons.arrow_left,
              ),
              const SizedBox(width: 8),
              Text(
                'scholarship.application_info'.tr,
                style: TextStyles.headerTextStyle,
              ),
            ],
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
                        items: const [
                          CreateScholarshipController
                              .duplicateStatusCanReceiveValue,
                          CreateScholarshipController
                              .duplicateStatusCannotReceiveExceptKykValue,
                        ],
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
                        items: const [
                          CreateScholarshipController.repayableYesValue,
                          CreateScholarshipController.repayableNoValue,
                        ],
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
                          CreateScholarshipController
                              .targetAudiencePopulationValue,
                          CreateScholarshipController
                              .targetAudienceResidenceValue,
                          CreateScholarshipController
                              .targetAudienceAllTurkeyValue,
                        ],
                        title: "scholarship.target_audience_label".tr,
                        selectedItem: controller.hedefKitle.value,
                        itemLabelBuilder: (item) =>
                            _targetAudienceLabel(item.toString()),
                        onSelect: (value) {
                          controller.hedefKitle.value = value;
                          if (value ==
                              CreateScholarshipController
                                  .targetAudienceAllTurkeyValue) {
                            controller.sehirler.clear();
                            controller.ilceler.clear();
                          }
                          if (value !=
                              CreateScholarshipController
                                  .educationAudienceUndergraduateValue) {
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
                          CreateScholarshipController.educationAudienceAllValue,
                          CreateScholarshipController
                              .educationAudienceMiddleSchoolValue,
                          CreateScholarshipController
                              .educationAudienceHighSchoolValue,
                          CreateScholarshipController
                              .educationAudienceUndergraduateValue,
                        ],
                        title: "scholarship.education_audience_label".tr,
                        selectedItem: controller.egitimKitlesi.value,
                        itemLabelBuilder: (item) =>
                            _educationAudienceLabel(item.toString()),
                        onSelect: (value) {
                          controller.egitimKitlesi.value = value;
                          if (value !=
                              CreateScholarshipController
                                  .educationAudienceUndergraduateValue) {
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
              () => controller.egitimKitlesi.value ==
                          CreateScholarshipController
                              .educationAudienceAllValue ||
                      controller.egitimKitlesi.value ==
                          CreateScholarshipController
                              .educationAudienceMiddleSchoolValue ||
                      controller.egitimKitlesi.value ==
                          CreateScholarshipController
                              .educationAudienceHighSchoolValue
                  ? const SizedBox.shrink()
                  : 8.pw,
            ),
            Obx(() {
              if (controller.egitimKitlesi.value ==
                  CreateScholarshipController
                      .educationAudienceUndergraduateValue) {
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
                                CreateScholarshipController
                                    .degreeAssociateValue,
                                CreateScholarshipController.degreeBachelorValue,
                                CreateScholarshipController.degreeMasterValue,
                                CreateScholarshipController.degreePhdValue,
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
                                          ? 'common.selected_count'.trParams({
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
        _buildTargetingSection(
          context,
          controller,
          containerDecoration,
        ),
        const SizedBox(height: 20),
        _buildExtraSectionActions(controller),
      ],
    );
  }
}
