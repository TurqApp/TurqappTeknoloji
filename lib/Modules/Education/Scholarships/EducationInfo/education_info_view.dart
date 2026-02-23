import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pull_down_button/pull_down_button.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/no_yes_alert.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/container_buttons.dart';
import 'package:turqappv2/Core/empty_row.dart';
import 'package:turqappv2/Modules/Education/Scholarships/EducationInfo/education_info_controller.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class EducationInfoView extends StatelessWidget {
  EducationInfoView({super.key});

  final EducationInfoController controller = Get.put(EducationInfoController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: BackButtons(text: "Eğitim Bilgileri"),
                ),
                PullDownButton(
                  itemBuilder: (context) => [
                    PullDownMenuItem(
                      title: 'Eğitim Bilgilerimi Sıfırla',
                      icon: CupertinoIcons.restart,
                      onTap: () {
                        noYesAlert(
                          title: "Emin misiniz?",
                          message:
                              "Eğitim bilgileriniz sıfırlanacak. Bu işlem geri alınamaz.",
                          cancelText: "İptal",
                          yesText: "Sıfırla",
                          onYesPressed: () async {
                            controller.clearFields();
                            await FirebaseFirestore.instance
                                .collection("users")
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .update({
                              'ulke': '',
                              'il': '',
                              'ilce': '',
                              'ortaOkul': '',
                              'lise': '',
                              'universite': '',
                              'fakulte': '',
                              'bolum': '',
                              'sinif': '',
                              'educationLevel': '',
                            });
                            await controller.loadSavedData();
                            controller.hasMiddleSchoolData.value = false;
                            controller.hasHighSchoolData.value = false;
                            controller.hasHigherEducationData.value = false;
                            controller.selectedEducationLevel.value = '';
                            AppSnackbar(
                              "Başarılı",
                              "Eğitim Bilgileriniz sıfırlandı.",
                            );
                          },
                        );
                      },
                    ),
                  ],
                  buttonBuilder: (context, showMenu) => IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: showMenu,
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Obx(
                () => Column(
                  children: [
                    SizedBox(height: 50),
                    if (!controller.isInitialLoading.value)
                      Expanded(
                        child: Column(
                          children: [
                            DropdownField(
                              config: FieldConfig(
                                label: "Eğitim Seviyesi",
                                items: [
                                  'Ortaokul',
                                  'Lise',
                                  'Önlisans',
                                  'Lisans',
                                  'Yüksek Lisans',
                                  'Doktora',
                                ],
                                value: controller.selectedEducationLevel,
                                onSelect: (selected) {
                                  controller.selectedEducationLevel.value =
                                      selected;
                                  controller.loadSavedDataForLevel(selected);
                                },
                                isSearchable: false,
                              ),
                              controller: controller,
                            ),
                            12.ph,
                            Expanded(child: _buildFormFields()),
                            20.ph,
                            _buildSaveButton(),
                            15.ph,
                          ],
                        ),
                      ),
                    if (controller.isInitialLoading.value ||
                        controller.isLoading.value)
                      Expanded(
                        child: Center(child: CupertinoActivityIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    switch (controller.selectedEducationLevel.value) {
      case 'Ortaokul':
        return _buildMiddleSchoolFields();
      case 'Lise':
        return _buildHighSchoolFields();
      case 'Önlisans':
        return _buildHigherEducationFields(isUndergraduate: false);
      case 'Lisans':
        return _buildHigherEducationFields(isUndergraduate: true);
      case 'Yüksek Lisans':
        return _buildHigherEducationFields(
          isUndergraduate: true,
        );
      case 'Doktora':
        return _buildHigherEducationFields(
          isUndergraduate: true,
        );
      default:
        return Center(
            child: EmptyRow(text: "Lütfen bir eğitim seviyesi seçin!"));
    }
  }

  Widget _buildMiddleSchoolFields() {
    return SingleChildScrollView(
      child: Column(
        children: [
          DropdownField(
            config: FieldConfig(
              label: "Ülke",
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
          SizedBox(height: 20),
          if (controller.selectedCountry.value.isNotEmpty)
            Row(
              children: [
                Flexible(
                  child: DropdownField(
                    config: FieldConfig(
                      label: "İl",
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
                SizedBox(width: 10),
                Flexible(
                  child: DropdownField(
                    config: FieldConfig(
                      label: "İlçe",
                      items: controller.cityDistrictData
                          .where(
                            (item) => item.il == controller.selectedCity.value,
                          )
                          .map((item) => item.ilce)
                          .toSet()
                          .toList(),
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
          SizedBox(height: 20),
          if (controller.selectedDistrict.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "Okul",
                items: [],
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
          SizedBox(height: 20),
          if (controller.selectedSchool.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "Sınıf",
                items: ['5. Sınıf', '6. Sınıf', '7. Sınıf', '8. Sınıf'],
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
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          DropdownField(
            config: FieldConfig(
              label: "Ülke",
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
          SizedBox(height: 20),
          if (controller.selectedCountry.value.isNotEmpty)
            Row(
              children: [
                Flexible(
                  child: DropdownField(
                    config: FieldConfig(
                      label: "İl",
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
                SizedBox(width: 10),
                Flexible(
                  child: DropdownField(
                    config: FieldConfig(
                      label: "İlçe",
                      items: controller.cityDistrictData
                          .where(
                            (item) => item.il == controller.selectedCity.value,
                          )
                          .map((item) => item.ilce)
                          .toSet()
                          .toList(),
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
          SizedBox(height: 20),
          if (controller.selectedDistrict.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "Lise",
                items: [],
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
          SizedBox(height: 20),
          if (controller.selectedHighSchool.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "Sınıf",
                items: ['9. Sınıf', '10. Sınıf', '11. Sınıf', '12. Sınıf'],
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
    String educationType = isDoctorate
        ? 'DOKTORA'
        : isMasters
            ? 'YÜKSEK LİSANS'
            : (isUndergraduate ? 'LİSANS' : 'ÖN LİSANS');

    return SingleChildScrollView(
      physics: AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          DropdownField(
            config: FieldConfig(
              label: "Ülke",
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
          SizedBox(height: 20),
          if (controller.selectedCountry.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "İl",
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
          SizedBox(height: 20),
          if (controller.selectedCity.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "Üniversite",
                items: controller.higherEducations
                    .where((edu) =>
                        edu.il == controller.selectedCity.value &&
                        edu.tip == educationType)
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
          SizedBox(height: 20),
          if (controller.selectedUniversity.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "Fakülte",
                items: controller.higherEducations
                    .where((edu) =>
                        edu.il == controller.selectedCity.value &&
                        edu.universite == controller.selectedUniversity.value &&
                        edu.tip == educationType)
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
          SizedBox(height: 20),
          if (controller.selectedFaculty.value.isNotEmpty)
            DropdownField(
              config: FieldConfig(
                label: "Bölüm",
                items: controller.higherEducations
                    .where((edu) =>
                        edu.il == controller.selectedCity.value &&
                        edu.universite == controller.selectedUniversity.value &&
                        edu.fakulte == controller.selectedFaculty.value &&
                        edu.tip == educationType)
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
    final String currentLevel = controller.selectedEducationLevel.value;
    String buttonText = 'Kaydet';

    if (currentLevel == 'Ortaokul' &&
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
    } else if (currentLevel == 'Lise' &&
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
          'Önlisans',
          'Lisans',
          'Yüksek Lisans',
          'Doktora',
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
    return SizedBox.shrink();
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
          config.label,
          style: TextStyle(
            color: Colors.black,
            fontSize: 15,
            fontFamily: "MontserratMedium",
          ),
        ),
        SizedBox(height: 8),
        GestureDetector(
          onTap: () => _toggleDropdown(context),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                        ? "${config.label} Seç"
                        : config.value.value,
                    style: TextStyle(
                      fontSize: 16,
                      color: config.value.value.isEmpty
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                ),
                Icon(CupertinoIcons.chevron_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
