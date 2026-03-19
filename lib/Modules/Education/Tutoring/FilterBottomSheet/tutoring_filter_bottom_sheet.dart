import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Modules/Education/Tutoring/FilterBottomSheet/tutoring_filter_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_controller.dart';
import 'package:flutter/material.dart';
import 'package:turqappv2/Core/BottomSheets/app_sheet_header.dart';
import 'package:turqappv2/Core/Widgets/pasaj_selection_chip.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Utils/empty_padding.dart';

class TutoringFilterBottomSheet extends StatelessWidget {
  final TutoringController controller;

  TutoringFilterBottomSheet({super.key, required this.controller});
  final TutoringFilterController filterController = Get.put(
    TutoringFilterController(),
  );

  String _branchLabel(String value) {
    const map = {
      'Yaz Okulu': 'tutoring.branch.summer_school',
      'Orta Öğretim': 'tutoring.branch.secondary_education',
      'İlk Öğretim': 'tutoring.branch.primary_education',
      'Yabancı Dil': 'tutoring.branch.foreign_language',
      'Yazılım': 'tutoring.branch.software',
      'Direksiyon': 'tutoring.branch.driving',
      'Spor': 'tutoring.branch.sports',
      'Sanat': 'tutoring.branch.art',
      'Müzik': 'tutoring.branch.music',
      'Tiyatro': 'tutoring.branch.theatre',
      'Kişisel Gelişim': 'tutoring.branch.personal_development',
      'Mesleki': 'tutoring.branch.vocational',
      'Özel Eğitim': 'tutoring.branch.special_education',
      'Çocuk': 'tutoring.branch.children',
      'Diksiyon': 'tutoring.branch.diction',
      'Fotoğrafçılık': 'tutoring.branch.photography',
    };
    return (map[value] ?? value).tr;
  }

  String _genderLabel(String value) {
    const map = {
      'Erkek': 'tutoring.gender.male',
      'Kadın': 'tutoring.gender.female',
      'Farketmez': 'tutoring.gender.any',
    };
    return (map[value] ?? value).tr;
  }

  String _sortLabel(String value) {
    const map = {
      'En Yeni': 'tutoring.sort.latest',
      'Bana En Yakın': 'tutoring.sort.nearest',
      'En Çok Görüntülenen': 'tutoring.sort.most_viewed',
    };
    return (map[value] ?? value).tr;
  }

  String _lessonPlaceLabel(String value) {
    const map = {
      'Öğrencinin Evi': 'tutoring.lesson_place.student_home',
      'Öğretmenin Evi': 'tutoring.lesson_place.teacher_home',
      'Öğrencinin veya Öğretmenin Evi':
          'tutoring.lesson_place.either_home',
      'Uzaktan Eğitim': 'tutoring.lesson_place.remote',
      'Ders Verme Alanı': 'tutoring.lesson_place.lesson_area',
    };
    return (map[value] ?? value).tr;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.all(15),
        constraints: BoxConstraints(maxHeight: Get.height * 0.9),
        child: Column(
          children: [
            AppSheetHeader(title: "tutoring.filter_title".tr),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      runAlignment: WrapAlignment.start,
                      children: <String>[
                        'Yaz Okulu',
                        'Orta Öğretim',
                        'İlk Öğretim',
                        'Yabancı Dil',
                        'Yazılım',
                        'Direksiyon',
                        'Spor',
                        'Sanat',
                        'Müzik',
                        'Tiyatro',
                        'Kişisel Gelişim',
                        'Mesleki',
                        'Özel Eğitim',
                        'Çocuk',
                        'Diksiyon',
                        'Fotoğrafçılık',
                      ].map((String value) {
                        return Obx(
                          () => PasajSelectionChip(
                            label: _branchLabel(value),
                            selected:
                                filterController.selectedBranch.value == value,
                            onTap: () {
                              filterController.selectedBranch.value =
                                  filterController.selectedBranch.value == value
                                      ? null
                                      : value;
                            },
                            width:
                                (MediaQuery.of(context).size.width - 32 - 16) /
                                    3,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            fontSize: 14,
                          ),
                        );
                      }).toList(),
                    ),
                    16.ph,
                    Text("tutoring.gender_title".tr,
                        style: TextStyles.bold18Black),
                    8.ph,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: <String>['Erkek', 'Kadın', 'Farketmez']
                          .map((String value) {
                        return Obx(
                          () => GestureDetector(
                            onTap: () {
                              filterController.selectedGender.value =
                                  filterController.selectedGender.value == value
                                      ? null
                                      : value;
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  filterController.selectedGender.value == value
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color:
                                      filterController.selectedGender.value ==
                                              value
                                          ? Colors.green
                                          : Colors.grey,
                                ),
                                4.pw,
                                Text(
                                  _genderLabel(value),
                                  style: TextStyles.textFieldTitle,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    Divider(),
                    Text("tutoring.sort_title".tr,
                        style: TextStyles.bold18Black),
                    8.ph,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: <String>[
                        'En Yeni',
                        'Bana En Yakın',
                        'En Çok Görüntülenen',
                      ].map((String value) {
                        return Obx(
                          () => GestureDetector(
                            onTap: () {
                              filterController.selectedSort.value =
                                  filterController.selectedSort.value == value
                                      ? null
                                      : value;
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  filterController.selectedSort.value == value
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: filterController.selectedSort.value ==
                                          value
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                4.pw,
                                Text(
                                  _sortLabel(value),
                                  style: TextStyles.textFieldTitle,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    Divider(),
                    Text("tutoring.lesson_place_title".tr,
                        style: TextStyles.bold18Black),
                    8.ph,
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.start,
                      children: <String>[
                        'Öğrencinin Evi',
                        'Öğretmenin Evi',
                        'Öğrencinin veya Öğretmenin Evi',
                        'Uzaktan Eğitim',
                        'Ders Verme Alanı',
                      ].map((String value) {
                        return Obx(
                          () => GestureDetector(
                            onTap: () {
                              if (filterController.selectedLessonPlace.value!
                                  .contains(value)) {
                                filterController.selectedLessonPlace.value!
                                    .remove(
                                  value,
                                );
                              } else {
                                filterController.selectedLessonPlace.value!.add(
                                  value,
                                );
                              }
                              filterController.selectedLessonPlace.refresh();
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(
                                  filterController.selectedLessonPlace.value!
                                          .contains(value)
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: filterController
                                          .selectedLessonPlace.value!
                                          .contains(value)
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                4.pw,
                                Text(
                                  _lessonPlaceLabel(value),
                                  style: TextStyles.textFieldTitle,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    Divider(),
                    Text("tutoring.service_location_title".tr,
                        style: TextStyles.bold18Black),
                    8.ph,
                    Obx(
                      () => Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: filterController.showIlSec,
                              child: Container(
                                height: 50,
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  borderRadius: const BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 15),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        filterController.city.value.isEmpty
                                            ? "common.select_city".tr
                                            : filterController.city.value,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium",
                                        ),
                                      ),
                                      const Icon(CupertinoIcons.chevron_down,
                                          size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (filterController.city.value.isNotEmpty)
                            const SizedBox(width: 12),
                          if (filterController.city.value.isNotEmpty)
                            Expanded(
                              child: GestureDetector(
                                onTap: filterController.showIlcelerSec,
                                child: Container(
                                  height: 50,
                                  alignment: Alignment.centerLeft,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(12),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          filterController.town.value.isEmpty
                                              ? "common.select_district".tr
                                              : filterController.town.value,
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontSize: 15,
                                            fontFamily: "MontserratMedium",
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
                            ),
                        ],
                      ),
                    ),
                    16.ph,
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              filterController.clearFilters();
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border:
                                    Border.all(color: Colors.black, width: 1),
                              ),
                              child: Text("common.reset".tr,
                                  style: TextStyles.bold16Black),
                            ),
                          ),
                        ),
                        8.pw,
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              filterController.applyFilters();
                            },
                            child: Container(
                              alignment: Alignment.center,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child:
                                  Text("common.apply".tr, style: TextStyles.bold16White),
                            ),
                          ),
                        ),
                      ],
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
}
