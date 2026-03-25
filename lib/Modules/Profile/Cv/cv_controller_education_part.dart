part of 'cv_controller.dart';

extension CvControllerEducationPart on CvController {
  Future<void> okulEkle() async {
    TextEditingController okul = TextEditingController();
    TextEditingController bolum = TextEditingController();
    TextEditingController yil = TextEditingController();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height / 2),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'cv.add_school_title'.tr,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    if (okul.text.trim().isEmpty) {
                      AppSnackbar(
                        'cv.missing_field'.tr,
                        'cv.missing_school_name'.tr,
                      );
                      return;
                    }
                    if (yil.text.isNotEmpty &&
                        !isPresentCvYear(yil.text) &&
                        !_validateYear(yil.text)) {
                      AppSnackbar('common.error'.tr, 'cv.invalid_year'.tr);
                      return;
                    }
                    okullar.add(CvSchoolModel(
                      school: okul.text.trim(),
                      branch: bolum.text.trim(),
                      lastYear: yil.text.trim(),
                    ));
                    Get.back();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'social_links.add'.tr,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                ),
              ],
            ),
            _textFieldBox(okul, 'cv.school_name'.tr),
            SizedBox(height: 15),
            _textFieldBox(bolum, 'cv.department'.tr),
            SizedBox(height: 15),
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: yil,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(4),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: 'cv.graduation_year'.tr,
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: "MontserratMedium",
                        ),
                        border: InputBorder.none,
                        counterText: "",
                      ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => yil.text = 'cv.ongoing'.tr,
                    child: Text(
                      'cv.currently_studying'.tr,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 14,
                        fontFamily: "MontserratMedium",
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void okulDuzenle(int index) {
    final model = okullar[index];
    TextEditingController okul = TextEditingController(text: model.school);
    TextEditingController bolum = TextEditingController(text: model.branch);
    TextEditingController yil = TextEditingController(text: model.lastYear);

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height / 2),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'cv.edit_school_title'.tr,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (okul.text.trim().isEmpty) {
                      AppSnackbar(
                        'cv.missing_field'.tr,
                        'cv.missing_school_name'.tr,
                      );
                      return;
                    }
                    if (yil.text.isNotEmpty &&
                        !isPresentCvYear(yil.text) &&
                        !_validateYear(yil.text)) {
                      AppSnackbar('common.error'.tr, 'cv.invalid_year'.tr);
                      return;
                    }
                    okullar[index] = CvSchoolModel(
                      school: okul.text.trim(),
                      branch: bolum.text.trim(),
                      lastYear: yil.text.trim(),
                    );
                    okullar.refresh();
                    Get.back();
                  },
                  child: Text(
                    'cv.save'.tr,
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                ),
              ],
            ),
            _textFieldBox(okul, 'cv.school_name'.tr),
            SizedBox(height: 15),
            _textFieldBox(bolum, 'cv.department'.tr),
            SizedBox(height: 15),
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: yil,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(4),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: InputDecoration(
                        hintText: 'cv.graduation_year'.tr,
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontFamily: "MontserratMedium",
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => yil.text = 'cv.ongoing'.tr,
                    child: Text(
                      'cv.currently_studying'.tr,
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 14,
                        fontFamily: "MontserratMedium",
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 15),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> dilEkle() async {
    RxString selectedDil = ''.obs;
    RxInt selectedSeviye = 3.obs;

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height / 2),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'cv.add_language_title'.tr,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
                Obx(
                  () => TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: selectedDil.value.isEmpty
                        ? null
                        : () {
                            diler.add(
                              CVLanguegeModel(
                                languege: selectedDil.value,
                                level: selectedSeviye.toInt(),
                                index: diler.length + 10000,
                              ),
                            );
                            Get.back();
                          },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'social_links.add'.tr,
                        style: TextStyle(
                          color: selectedDil.value.isEmpty
                              ? Colors.grey
                              : Colors.blueAccent,
                          fontSize: 15,
                          fontFamily: "MontserratBold",
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: CvController.languageOptionKeys.map((dil) {
                    final bool isSelected = selectedDil.value == dil;
                    return GestureDetector(
                      onTap: () => selectedDil.value = dil,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          localizedLanguage(dil),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "MontserratMedium",
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'cv.level'.tr,
              style: TextStyle(
                fontFamily: "MontserratMedium",
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Row(
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () => selectedSeviye.value = index + 1,
                    child: Icon(
                      index < selectedSeviye.value
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      color: index < selectedSeviye.value
                          ? Colors.amber
                          : Colors.grey,
                      size: 28,
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 25),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void dilDuzenle(int index) {
    final model = diler[index];
    RxString selectedDil = normalizeLanguageValue(model.languege).obs;
    RxInt selectedSeviye = model.level.toInt().obs;

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height / 2),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'cv.edit_language_title'.tr,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
                Obx(
                  () => TextButton(
                    onPressed: selectedDil.value.isEmpty
                        ? null
                        : () {
                            diler[index] = CVLanguegeModel(
                              languege: selectedDil.value,
                              level: selectedSeviye.toInt(),
                              index: model.index,
                            );
                            diler.refresh();
                            Get.back();
                          },
                    child: Text(
                      'cv.save'.tr,
                      style: TextStyle(
                        color: selectedDil.value.isEmpty
                            ? Colors.grey
                            : Colors.blueAccent,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: CvController.languageOptionKeys.map((dil) {
                    final bool isSelected = selectedDil.value == dil;
                    return GestureDetector(
                      onTap: () => selectedDil.value = dil,
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.blueAccent
                              : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          localizedLanguage(dil),
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: "MontserratMedium",
                            color: isSelected ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'cv.level'.tr,
              style: TextStyle(
                fontFamily: "MontserratMedium",
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Obx(
              () => Row(
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => selectedSeviye.value = i + 1,
                    child: Icon(
                      i < selectedSeviye.value
                          ? CupertinoIcons.star_fill
                          : CupertinoIcons.star,
                      color:
                          i < selectedSeviye.value ? Colors.amber : Colors.grey,
                      size: 28,
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 25),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
