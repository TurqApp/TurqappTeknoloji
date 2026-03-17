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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: EdgeInsets.all(15),
        constraints: BoxConstraints(maxHeight: Get.height * 0.9),
        child: Column(
          children: [
            const AppSheetHeader(title: "Filtreler"),
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
                            label: value,
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
                    Text("Cinsiyet", style: TextStyles.bold18Black),
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
                                Text(value, style: TextStyles.textFieldTitle),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    Divider(),
                    Text("Sıralama", style: TextStyles.bold18Black),
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
                                Text(value, style: TextStyles.textFieldTitle),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    Divider(),
                    Text("Ders Yeri", style: TextStyles.bold18Black),
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
                                Text(value, style: TextStyles.textFieldTitle),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    Divider(),
                    Text("Hizmet Verilen Yer", style: TextStyles.bold18Black),
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
                                            ? "Şehir Seç"
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
                                              ? "İlçe Seç"
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
                              child: Text("Sıfırla",
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
                                  Text("Uygula", style: TextStyles.bold16White),
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
