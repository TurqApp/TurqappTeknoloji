part of 'cv_controller.dart';

extension CvControllerSectionsPart on CvController {
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
                          'cv.missing_field'.tr, 'cv.missing_school_name'.tr);
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
                )
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
                Text('cv.edit_school_title'.tr,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold")),
                TextButton(
                  onPressed: () {
                    if (okul.text.trim().isEmpty) {
                      AppSnackbar(
                          'cv.missing_field'.tr, 'cv.missing_school_name'.tr);
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
                  child: Text('cv.save'.tr,
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontFamily: "MontserratBold")),
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
                            color: Colors.grey, fontFamily: "MontserratMedium"),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium"),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => yil.text = 'cv.ongoing'.tr,
                    child: Text('cv.currently_studying'.tr,
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 14,
                            fontFamily: "MontserratMedium",
                            decoration: TextDecoration.underline)),
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

  // ── Language ──

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
                Text('cv.add_language_title'.tr,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold")),
                Obx(() => TextButton(
                      style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                      onPressed: selectedDil.value.isEmpty
                          ? null
                          : () {
                              diler.add(CVLanguegeModel(
                                  languege: selectedDil.value,
                                  level: selectedSeviye.toInt(),
                                  index: diler.length + 10000));
                              Get.back();
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('social_links.add'.tr,
                            style: TextStyle(
                                color: selectedDil.value.isEmpty
                                    ? Colors.grey
                                    : Colors.blueAccent,
                                fontSize: 15,
                                fontFamily: "MontserratBold")),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: CvController.languageOptionKeys.map((dil) {
                      final bool isSelected = selectedDil.value == dil;
                      return GestureDetector(
                        onTap: () => selectedDil.value = dil,
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(localizedLanguage(dil),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: "MontserratMedium",
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black)),
                        ),
                      );
                    }).toList(),
                  ),
                )),
            const SizedBox(height: 20),
            Text('cv.level'.tr,
                style: TextStyle(
                    fontFamily: "MontserratMedium",
                    fontSize: 14,
                    color: Colors.black)),
            const SizedBox(height: 8),
            Obx(() => Row(
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
                )),
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
    RxInt selectedSeviye = (model.level.toInt()).obs;

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
                Text('cv.edit_language_title'.tr,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold")),
                Obx(() => TextButton(
                      onPressed: selectedDil.value.isEmpty
                          ? null
                          : () {
                              diler[index] = CVLanguegeModel(
                                  languege: selectedDil.value,
                                  level: selectedSeviye.toInt(),
                                  index: model.index);
                              diler.refresh();
                              Get.back();
                            },
                      child: Text('cv.save'.tr,
                          style: TextStyle(
                              color: selectedDil.value.isEmpty
                                  ? Colors.grey
                                  : Colors.blueAccent,
                              fontFamily: "MontserratBold")),
                    )),
              ],
            ),
            const SizedBox(height: 10),
            Obx(() => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: CvController.languageOptionKeys.map((dil) {
                      final bool isSelected = selectedDil.value == dil;
                      return GestureDetector(
                        onTap: () => selectedDil.value = dil,
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.blueAccent
                                : Colors.grey.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(localizedLanguage(dil),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: "MontserratMedium",
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black)),
                        ),
                      );
                    }).toList(),
                  ),
                )),
            const SizedBox(height: 20),
            Text('cv.level'.tr,
                style: TextStyle(
                    fontFamily: "MontserratMedium",
                    fontSize: 14,
                    color: Colors.black)),
            const SizedBox(height: 8),
            Obx(() => Row(
                  children: List.generate(5, (i) {
                    return GestureDetector(
                      onTap: () => selectedSeviye.value = i + 1,
                      child: Icon(
                        i < selectedSeviye.value
                            ? CupertinoIcons.star_fill
                            : CupertinoIcons.star,
                        color: i < selectedSeviye.value
                            ? Colors.amber
                            : Colors.grey,
                        size: 28,
                      ),
                    );
                  }),
                )),
            SizedBox(height: 25),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Experience ──

  Future<void> isDeneyimiEkle() async {
    TextEditingController firmaAdi = TextEditingController();
    TextEditingController pozisyon = TextEditingController();
    TextEditingController yil1 = TextEditingController();
    TextEditingController yil2 = TextEditingController();
    TextEditingController aciklama = TextEditingController();
    RxBool halenCalisiyorum = false.obs;

    _showExperienceSheet(
      title: 'cv.add_experience_title'.tr,
      buttonText: 'social_links.add'.tr,
      firmaAdi: firmaAdi,
      pozisyon: pozisyon,
      yil1: yil1,
      yil2: yil2,
      aciklama: aciklama,
      halenCalisiyorum: halenCalisiyorum,
      onSave: () {
        if (firmaAdi.text.trim().isEmpty || pozisyon.text.trim().isEmpty) {
          AppSnackbar(
              'cv.missing_field'.tr, 'cv.missing_company_position'.tr);
          return;
        }
        if (yil1.text.isNotEmpty && !_validateYear(yil1.text)) {
          AppSnackbar('common.error'.tr, 'cv.invalid_start_year'.tr);
          return;
        }
        if (yil2.text.isNotEmpty && !_validateYear(yil2.text)) {
          AppSnackbar('common.error'.tr, 'cv.invalid_end_year'.tr);
          return;
        }
        Get.back();
        isDeneyimleri.add(CVExperinceModel(
          company: firmaAdi.text.trim(),
          position: pozisyon.text.trim(),
          year1: yil1.text.trim(),
          year2:
              halenCalisiyorum.value ? 'cv.ongoing'.tr : yil2.text.trim(),
          description: aciklama.text.trim(),
        ));
      },
    );
  }

  void isDeneyimiDuzenle(int index) {
    final model = isDeneyimleri[index];
    final ongoingLabels = <String>{
      'Devam Ediyor',
      'cv.ongoing'.tr,
      'Ongoing',
      'Läuft noch',
      'En cours',
      'In corso',
      'Продолжается',
    };
    TextEditingController firmaAdi = TextEditingController(text: model.company);
    TextEditingController pozisyon =
        TextEditingController(text: model.position);
    TextEditingController yil1 = TextEditingController(text: model.year1);
    TextEditingController yil2 = TextEditingController(
        text: ongoingLabels.contains(model.year2) ? "" : model.year2);
    TextEditingController aciklama =
        TextEditingController(text: model.description);
    RxBool halenCalisiyorum = ongoingLabels.contains(model.year2).obs;

    _showExperienceSheet(
      title: 'cv.edit_experience_title'.tr,
      buttonText: 'cv.save'.tr,
      firmaAdi: firmaAdi,
      pozisyon: pozisyon,
      yil1: yil1,
      yil2: yil2,
      aciklama: aciklama,
      halenCalisiyorum: halenCalisiyorum,
      onSave: () {
        if (firmaAdi.text.trim().isEmpty || pozisyon.text.trim().isEmpty) {
          AppSnackbar(
              'cv.missing_field'.tr, 'cv.missing_company_position'.tr);
          return;
        }
        if (yil1.text.isNotEmpty && !_validateYear(yil1.text)) {
          AppSnackbar('common.error'.tr, 'cv.invalid_start_year'.tr);
          return;
        }
        if (yil2.text.isNotEmpty && !_validateYear(yil2.text)) {
          AppSnackbar('common.error'.tr, 'cv.invalid_end_year'.tr);
          return;
        }
        isDeneyimleri[index] = CVExperinceModel(
          company: firmaAdi.text.trim(),
          position: pozisyon.text.trim(),
          year1: yil1.text.trim(),
          year2:
              halenCalisiyorum.value ? 'cv.ongoing'.tr : yil2.text.trim(),
          description: aciklama.text.trim(),
        );
        isDeneyimleri.refresh();
        Get.back();
      },
    );
  }

  void _showExperienceSheet({
    required String title,
    required String buttonText,
    required TextEditingController firmaAdi,
    required TextEditingController pozisyon,
    required TextEditingController yil1,
    required TextEditingController yil2,
    required TextEditingController aciklama,
    required RxBool halenCalisiyorum,
    required VoidCallback onSave,
  }) {
    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: Get.height * 0.65),
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: Colors.black,
                          fontSize: 18,
                          fontFamily: "MontserratBold")),
                  TextButton(
                    onPressed: onSave,
                    child: Text(buttonText,
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontFamily: "MontserratBold")),
                  ),
                ],
              ),
              SizedBox(height: 15),
              _textFieldBox(firmaAdi, 'cv.company_name'.tr),
              SizedBox(height: 15),
              _textFieldBox(pozisyon, 'cv.position'.tr),
              SizedBox(height: 15),
              // Description
              Container(
                height: 80,
                alignment: Alignment.topLeft,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: TextField(
                  controller: aciklama,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: 'cv.description_optional'.tr,
                    hintStyle: TextStyle(
                        color: Colors.grey, fontFamily: "MontserratMedium"),
                    border: InputBorder.none,
                    counterText: "",
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontFamily: "MontserratMedium"),
                ),
              ),
              SizedBox(height: 15),
              // Years
              Obx(() => Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 50,
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: TextField(
                            controller: yil1,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(4),
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              hintText: 'cv.start_year'.tr,
                              hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontFamily: "MontserratMedium"),
                              border: InputBorder.none,
                            ),
                            style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium"),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Opacity(
                          opacity: halenCalisiyorum.value ? 0.4 : 1.0,
                          child: Container(
                            height: 50,
                            alignment: Alignment.centerLeft,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.03),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: TextField(
                              controller: yil2,
                              enabled: !halenCalisiyorum.value,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(4),
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText: halenCalisiyorum.value
                                    ? 'cv.ongoing'.tr
                                    : 'cv.end_year'.tr,
                                hintStyle: TextStyle(
                                  color: Colors.grey,
                                  fontStyle: halenCalisiyorum.value
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                                  fontFamily: "MontserratMedium",
                                ),
                                border: InputBorder.none,
                              ),
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium"),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Obx(() => Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: GestureDetector(
                          onTap: () {
                            halenCalisiyorum.toggle();
                            if (halenCalisiyorum.value) yil2.clear();
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 25,
                                height: 25,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(4)),
                                  color: halenCalisiyorum.value
                                      ? Colors.black
                                      : Colors.transparent,
                                  border: Border.all(color: Colors.black),
                                ),
                                child: Icon(CupertinoIcons.checkmark,
                                    color: Colors.white, size: 20),
                              ),
                              SizedBox(width: 7),
                              Text('cv.currently_working'.tr,
                                  style: TextStyle(
                                      color: Colors.blueAccent,
                                      fontSize: 14,
                                      fontFamily: "MontserratMedium")),
                            ],
                          ),
                        ),
                      )),
                ],
              ),
              SizedBox(height: 15),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Reference ──
}
