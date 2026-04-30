part of 'education_info_view.dart';

extension _EducationInfoViewFieldsPart on _EducationInfoViewState {
  Widget _buildFormFields() {
    switch (controller.selectedEducationLevel.value) {
      case _
          when controller.selectedEducationLevel.value ==
              controller.middleSchoolValue:
        return _buildMiddleSchoolFields();
      case _
          when controller.selectedEducationLevel.value ==
              controller.highSchoolValue:
        return _buildHighSchoolFields();
      case _
          when controller.selectedEducationLevel.value ==
              controller.associateValue:
        return _buildHigherEducationFields(isUndergraduate: false);
      case _
          when controller.selectedEducationLevel.value ==
              controller.bachelorValue:
        return _buildHigherEducationFields(isUndergraduate: true);
      case _
          when controller.selectedEducationLevel.value ==
              controller.mastersValue:
        return _buildHigherEducationFields(isUndergraduate: true);
      case _
          when controller.selectedEducationLevel.value ==
              controller.doctorateValue:
        return _buildHigherEducationFields(isUndergraduate: true);
      default:
        return AppStateView.empty(title: 'education_info.select_level'.tr);
    }
  }

  Widget _buildMiddleSchoolFields() {
    return SingleChildScrollView(
      child: Column(
        children: [
          DropdownField(
            config: FieldConfig(
              label: "scholarship.country_label".tr,
              items: controller.countries,
              value: controller.selectedCountry,
              onSelect: (selected) {
                controller.selectedCountry.value = selected;
                controller.selectedCity.value = '';
                controller.selectedDistrict.value = '';
                controller.selectedSchool.value = '';
                controller.selectedClassLevel.value = '';
                controller.updateContent();
              },
              isSearchable: true,
            ),
            controller: controller,
          ),
          20.ph,
          if (controller.selectedCountry.value.isNotEmpty)
            Row(
              children: [
                Flexible(
                  child: DropdownField(
                    config: FieldConfig(
                      label: "common.city".tr,
                      items: controller.cities,
                      value: controller.selectedCity,
                      onSelect: (selected) {
                        controller.selectedCity.value = selected;
                        controller.selectedDistrict.value = '';
                        controller.selectedSchool.value = '';
                        controller.selectedClassLevel.value = '';
                        controller.updateContent();
                      },
                      isSearchable: true,
                    ),
                    controller: controller,
                  ),
                ),
                10.pw,
                Flexible(
                  child: DropdownField(
                    config: FieldConfig(
                      label: "common.district".tr,
                      items: (() {
                        final districts = controller.cityDistrictData
                            .where(
                              (item) =>
                                  item.il == controller.selectedCity.value,
                            )
                            .map((item) => item.ilce)
                            .toSet()
                            .toList();
                        sortTurkishStrings(districts);
                        return districts;
                      })(),
                      value: controller.selectedDistrict,
                      onSelect: (selected) {
                        controller.selectedDistrict.value = selected;
                        controller.selectedSchool.value = '';
                        controller.selectedClassLevel.value = '';
                        controller.updateContent();
                      },
                      isSearchable: true,
                    ),
                    controller: controller,
                  ),
                ),
              ],
            ),
          20.ph,
          if (controller.selectedDistrict.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "education_info.middle_school".tr,
                items: const [],
                value: controller.selectedSchool,
                onSelect: (selected) {
                  controller.selectedSchool.value = selected;
                  controller.selectedClassLevel.value = '';
                  controller.updateContent();
                },
                isSearchable: true,
              ),
              controller: controller,
              isSchoolField: true,
            ),
          20.ph,
          if (controller.selectedSchool.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "education_info.class_level".tr,
                items: const ['5', '6', '7', '8'],
                value: controller.selectedClassLevel,
                onSelect: (selected) {
                  controller.selectedClassLevel.value = selected;
                  controller.updateContent();
                },
                isSearchable: false,
              ),
              controller: controller,
            ),
        ],
      ),
    );
  }

  Widget _buildHighSchoolFields() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          DropdownField(
            config: FieldConfig(
              label: "scholarship.country_label".tr,
              items: controller.countries,
              value: controller.selectedCountry,
              onSelect: (selected) {
                controller.selectedCountry.value = selected;
                controller.selectedCity.value = '';
                controller.selectedDistrict.value = '';
                controller.selectedHighSchool.value = '';
                controller.selectedClassLevel.value = '';
                controller.updateContent();
              },
              isSearchable: true,
            ),
            controller: controller,
          ),
          20.ph,
          if (controller.selectedCountry.value.isNotEmpty)
            Row(
              children: [
                Flexible(
                  child: DropdownField(
                    config: FieldConfig(
                      label: "common.city".tr,
                      items: controller.cities,
                      value: controller.selectedCity,
                      onSelect: (selected) {
                        controller.selectedCity.value = selected;
                        controller.selectedDistrict.value = '';
                        controller.selectedHighSchool.value = '';
                        controller.selectedClassLevel.value = '';
                        controller.updateContent();
                      },
                      isSearchable: true,
                    ),
                    controller: controller,
                  ),
                ),
                10.pw,
                Flexible(
                  child: DropdownField(
                    config: FieldConfig(
                      label: "common.district".tr,
                      items: (() {
                        final districts = controller.cityDistrictData
                            .where(
                              (item) =>
                                  item.il == controller.selectedCity.value,
                            )
                            .map((item) => item.ilce)
                            .toSet()
                            .toList();
                        sortTurkishStrings(districts);
                        return districts;
                      })(),
                      value: controller.selectedDistrict,
                      onSelect: (selected) {
                        controller.selectedDistrict.value = selected;
                        controller.selectedHighSchool.value = '';
                        controller.selectedClassLevel.value = '';
                        controller.updateContent();
                      },
                      isSearchable: true,
                    ),
                    controller: controller,
                  ),
                ),
              ],
            ),
          20.ph,
          if (controller.selectedDistrict.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "education_info.high_school".tr,
                items: const [],
                value: controller.selectedHighSchool,
                onSelect: (selected) {
                  controller.selectedHighSchool.value = selected;
                  controller.selectedClassLevel.value = '';
                  controller.updateContent();
                },
                isSearchable: true,
              ),
              controller: controller,
              isHighSchoolField: true,
            ),
          20.ph,
          if (controller.selectedHighSchool.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "education_info.class_level".tr,
                items: const ['9', '10', '11', '12'],
                value: controller.selectedClassLevel,
                onSelect: (selected) {
                  controller.selectedClassLevel.value = selected;
                  controller.updateContent();
                },
                isSearchable: false,
              ),
              controller: controller,
            ),
        ],
      ),
    );
  }

  Widget _buildHigherEducationFields({
    required bool isUndergraduate,
    bool isMasters = false,
    bool isDoctorate = false,
  }) {
    final educationType = isDoctorate
        ? 'DOKTORA'
        : isMasters
            ? 'YÜKSEK LİSANS'
            : (isUndergraduate ? 'LİSANS' : 'ÖN LİSANS');

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          DropdownField(
            config: FieldConfig(
              label: "scholarship.country_label".tr,
              items: controller.countries,
              value: controller.selectedCountry,
              onSelect: (selected) {
                controller.selectedCountry.value = selected;
                controller.selectedCity.value = '';
                controller.selectedUniversity.value = '';
                controller.selectedFaculty.value = '';
                controller.selectedDepartment.value = '';
                controller.updateContent();
              },
              isSearchable: true,
            ),
            controller: controller,
          ),
          20.ph,
          if (controller.selectedCountry.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "common.city".tr,
                items: controller.cities,
                value: controller.selectedCity,
                onSelect: (selected) {
                  controller.selectedCity.value = selected;
                  controller.selectedUniversity.value = '';
                  controller.selectedFaculty.value = '';
                  controller.selectedDepartment.value = '';
                  controller.updateContent();
                },
                isSearchable: true,
              ),
              controller: controller,
            ),
          20.ph,
          if (controller.selectedCity.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "common.university".tr,
                items: controller.higherEducations
                    .where(
                      (edu) =>
                          edu.il == controller.selectedCity.value &&
                          edu.tip == educationType,
                    )
                    .map((edu) => edu.universite)
                    .toSet()
                    .toList(),
                value: controller.selectedUniversity,
                onSelect: (selected) {
                  controller.selectedUniversity.value = selected;
                  controller.selectedFaculty.value = '';
                  controller.selectedDepartment.value = '';
                  controller.updateContent();
                },
                isSearchable: true,
              ),
              controller: controller,
            ),
          20.ph,
          if (controller.selectedUniversity.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "scholarship.applicant.faculty".tr,
                items: controller.higherEducations
                    .where(
                      (edu) =>
                          edu.il == controller.selectedCity.value &&
                          edu.universite ==
                              controller.selectedUniversity.value &&
                          edu.tip == educationType,
                    )
                    .map((edu) => edu.fakulte)
                    .toSet()
                    .toList(),
                value: controller.selectedFaculty,
                onSelect: (selected) {
                  controller.selectedFaculty.value = selected;
                  controller.selectedDepartment.value = '';
                  controller.updateContent();
                },
                isSearchable: true,
              ),
              controller: controller,
            ),
          20.ph,
          if (controller.selectedFaculty.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "scholarship.applicant.department".tr,
                items: controller.higherEducations
                    .where(
                      (edu) =>
                          edu.il == controller.selectedCity.value &&
                          edu.universite ==
                              controller.selectedUniversity.value &&
                          edu.fakulte == controller.selectedFaculty.value &&
                          edu.tip == educationType,
                    )
                    .map((edu) => edu.bolum)
                    .toList(),
                value: controller.selectedDepartment,
                onSelect: (selected) {
                  controller.selectedDepartment.value = selected;
                  controller.updateContent();
                },
                isSearchable: true,
              ),
              controller: controller,
            ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    final currentLevel = controller.selectedEducationLevel.value;
    final buttonText = 'common.save'.tr;

    if (currentLevel == controller.middleSchoolValue &&
        controller.selectedCountry.value.isNotEmpty &&
        controller.selectedCity.value.isNotEmpty &&
        controller.selectedDistrict.value.isNotEmpty &&
        controller.selectedSchool.value.isNotEmpty &&
        controller.selectedClassLevel.value.isNotEmpty) {
      return SaveButton(
        isLoading: controller.isLoading,
        selectedSchool: controller.selectedSchool,
        selectedClassLevel: controller.selectedClassLevel,
        onTap: controller.saveMiddleSchool,
        text: buttonText,
      );
    } else if (currentLevel == controller.highSchoolValue &&
        controller.selectedCountry.value.isNotEmpty &&
        controller.selectedCity.value.isNotEmpty &&
        controller.selectedDistrict.value.isNotEmpty &&
        controller.selectedHighSchool.value.isNotEmpty &&
        controller.selectedClassLevel.value.isNotEmpty) {
      return SaveButton(
        isLoading: controller.isLoading,
        selectedSchool: controller.selectedHighSchool,
        selectedClassLevel: controller.selectedClassLevel,
        onTap: controller.saveHighSchool,
        text: buttonText,
      );
    } else if ([
          controller.associateValue,
          controller.bachelorValue,
          controller.mastersValue,
          controller.doctorateValue,
        ].contains(currentLevel) &&
        controller.selectedCountry.value.isNotEmpty &&
        controller.selectedCity.value.isNotEmpty &&
        controller.selectedUniversity.value.isNotEmpty &&
        controller.selectedFaculty.value.isNotEmpty &&
        controller.selectedDepartment.value.isNotEmpty) {
      return SaveButton(
        isLoading: controller.isLoading,
        selectedSchool: controller.selectedUniversity,
        selectedClassLevel: controller.selectedDepartment,
        onTap: controller.saveHigherEducation,
        text: buttonText,
      );
    }
    return const SizedBox.shrink();
  }
}

class FieldConfig {
  final String label;
  final List<String> items;
  final Rx<String> value;
  final Function(String) onSelect;
  final bool isSearchable;

  FieldConfig({
    required this.label,
    required this.items,
    required this.value,
    required this.onSelect,
    required this.isSearchable,
  });
}

class DropdownField extends StatelessWidget {
  final FieldConfig config;
  final EducationInfoController controller;
  final bool isSchoolField;
  final bool isHighSchoolField;
  final bool isUniversityField;
  final bool isFacultyField;
  final bool isDepartmentField;
  final String? educationType;

  const DropdownField({
    super.key,
    required this.config,
    required this.controller,
    this.isSchoolField = false,
    this.isHighSchoolField = false,
    this.isUniversityField = false,
    this.isFacultyField = false,
    this.isDepartmentField = false,
    this.educationType,
  });

  void _toggleDropdown(BuildContext context) async {
    List<String> items = [];

    if (isSchoolField) {
      items = controller.middleSchools
          .where(
            (school) =>
                school.il == controller.selectedCity.value &&
                school.ilce == controller.selectedDistrict.value,
          )
          .map((school) => school.adi)
          .toList();
    } else if (isHighSchoolField) {
      items = controller.highSchools
          .where(
            (school) =>
                school.il == controller.selectedCity.value &&
                school.ilce == controller.selectedDistrict.value,
          )
          .map((school) => school.adi)
          .toList();
    } else if (isUniversityField) {
      items = controller.higherEducations
          .where((edu) => edu.il == controller.selectedCity.value)
          .map((edu) => edu.universite)
          .toSet()
          .toList();
    } else if (isFacultyField) {
      items = controller.higherEducations
          .where(
            (edu) =>
                edu.il == controller.selectedCity.value &&
                edu.universite == controller.selectedUniversity.value,
          )
          .map((edu) => edu.fakulte)
          .toSet()
          .toList();
    } else if (isDepartmentField) {
      items = controller.higherEducations
          .where(
            (edu) =>
                edu.il == controller.selectedCity.value &&
                edu.universite == controller.selectedUniversity.value &&
                edu.fakulte == controller.selectedFaculty.value,
          )
          .map((edu) => edu.bolum)
          .toList();
    } else {
      items = config.items;
    }

    await controller.showBottomSheet(
      context,
      items,
      config.label,
      config.onSelect,
      selectedItem: config.value.value.isEmpty ? null : config.value.value,
      isSearchable: config.isSearchable,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          controller.localizedFieldLabel(config.label),
          style: const TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
        8.ph,
        GestureDetector(
          onTap: () => _toggleDropdown(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    config.value.value.isEmpty
                        ? controller.localizedPlaceholder(config.label)
                        : controller.localizedOption(config.value.value),
                    style: TextStyle(
                      fontSize: 16,
                      color: config.value.value.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                const Icon(CupertinoIcons.chevron_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
