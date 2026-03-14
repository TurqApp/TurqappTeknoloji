import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Models/CVModels/school_model.dart';

class CvController extends GetxController {
  final CvRepository _cvRepository = CvRepository.ensure();
  var selection = 0.obs;
  TextEditingController firstName = TextEditingController(text: "");
  TextEditingController lastName = TextEditingController(text: "");
  TextEditingController linkedin = TextEditingController(text: "");
  TextEditingController mail = TextEditingController(text: "");
  TextEditingController phoneNumber = TextEditingController(text: "");
  TextEditingController onYazi = TextEditingController(text: "");

  RxList<CvSchoolModel> okullar = <CvSchoolModel>[].obs;
  RxList<CVLanguegeModel> diler = <CVLanguegeModel>[].obs;
  RxList<CVExperinceModel> isDeneyimleri = <CVExperinceModel>[].obs;
  RxList<CVReferenceHumans> referanslar = <CVReferenceHumans>[].obs;
  RxList<String> skills = <String>[].obs;
  RxBool isSaving = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadDataFromFirestore();
  }

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    mail.dispose();
    phoneNumber.dispose();
    linkedin.dispose();
    onYazi.dispose();
    super.onClose();
  }

  // ── Validations ──

  bool validateEmail(String email) {
    final regex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$');
    return regex.hasMatch(email);
  }

  bool validatePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length == 10 || digits.length == 11;
  }

  bool validateLinkedIn(String url) {
    final normalized = url.trim().toLowerCase();
    if (normalized.isEmpty) return true;
    return normalized.contains('linkedin.com/');
  }

  bool _validateYear(String year) {
    if (year == "Halen" || year.isEmpty) return true;
    final y = int.tryParse(year);
    if (y == null) return false;
    return y >= 1950 && y <= DateTime.now().year + 6;
  }

  // ── School ──

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
                  "Yeni Okul Ekle",
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
                      AppSnackbar("Eksik Alan", "Okul adı boş bırakılamaz");
                      return;
                    }
                    if (yil.text.isNotEmpty &&
                        yil.text != "Halen" &&
                        !_validateYear(yil.text)) {
                      AppSnackbar("Hata", "Geçerli bir yıl girin");
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
                      "Ekle",
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
            _textFieldBox(okul, "Okul Adı"),
            SizedBox(height: 15),
            _textFieldBox(bolum, "Bölüm"),
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
                        hintText: "Mezuniyet Yılı",
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
                    onTap: () => yil.text = "Halen",
                    child: Text(
                      "Devam Ediyorum",
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
                Text("Okul Düzenle",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold")),
                TextButton(
                  onPressed: () {
                    if (okul.text.trim().isEmpty) {
                      AppSnackbar("Eksik Alan", "Okul adı boş bırakılamaz");
                      return;
                    }
                    if (yil.text.isNotEmpty &&
                        yil.text != "Halen" &&
                        !_validateYear(yil.text)) {
                      AppSnackbar("Hata", "Geçerli bir yıl girin");
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
                  child: Text("Kaydet",
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontFamily: "MontserratBold")),
                ),
              ],
            ),
            _textFieldBox(okul, "Okul Adı"),
            SizedBox(height: 15),
            _textFieldBox(bolum, "Bölüm"),
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
                        hintText: "Mezuniyet Yılı",
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
                    onTap: () => yil.text = "Halen",
                    child: Text("Devam Ediyorum",
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

    final List<String> ornekdiller = [
      "İngilizce",
      "Almanca",
      "Fransızca",
      "İspanyolca",
      "Arapça",
      "Türkçe",
      "Rusça",
      "İtalyanca",
      "Korece",
    ];

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
                Text("Yeni Dil Ekle",
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
                        child: Text("Ekle",
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
                    children: ornekdiller.map((dil) {
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
                          child: Text(dil,
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
            Text("Seviye",
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
    RxString selectedDil = model.languege.obs;
    RxInt selectedSeviye = (model.level.toInt()).obs;

    final List<String> ornekdiller = [
      "İngilizce",
      "Almanca",
      "Fransızca",
      "İspanyolca",
      "Arapça",
      "Türkçe",
      "Rusça",
      "İtalyanca",
      "Korece",
    ];

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
                Text("Dil Düzenle",
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
                      child: Text("Kaydet",
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
                    children: ornekdiller.map((dil) {
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
                          child: Text(dil,
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
            Text("Seviye",
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
      title: "Yeni İş Deneyimi Ekle",
      buttonText: "Ekle",
      firmaAdi: firmaAdi,
      pozisyon: pozisyon,
      yil1: yil1,
      yil2: yil2,
      aciklama: aciklama,
      halenCalisiyorum: halenCalisiyorum,
      onSave: () {
        if (firmaAdi.text.trim().isEmpty || pozisyon.text.trim().isEmpty) {
          AppSnackbar("Eksik Alan", "Firma adı ve pozisyon zorunludur");
          return;
        }
        if (yil1.text.isNotEmpty && !_validateYear(yil1.text)) {
          AppSnackbar("Hata", "Geçerli bir başlangıç yılı girin");
          return;
        }
        if (yil2.text.isNotEmpty && !_validateYear(yil2.text)) {
          AppSnackbar("Hata", "Geçerli bir ayrılış yılı girin");
          return;
        }
        Get.back();
        isDeneyimleri.add(CVExperinceModel(
          company: firmaAdi.text.trim(),
          position: pozisyon.text.trim(),
          year1: yil1.text.trim(),
          year2: halenCalisiyorum.value ? "Devam Ediyor" : yil2.text.trim(),
          description: aciklama.text.trim(),
        ));
      },
    );
  }

  void isDeneyimiDuzenle(int index) {
    final model = isDeneyimleri[index];
    TextEditingController firmaAdi = TextEditingController(text: model.company);
    TextEditingController pozisyon =
        TextEditingController(text: model.position);
    TextEditingController yil1 = TextEditingController(text: model.year1);
    TextEditingController yil2 = TextEditingController(
        text: model.year2 == "Devam Ediyor" ? "" : model.year2);
    TextEditingController aciklama =
        TextEditingController(text: model.description);
    RxBool halenCalisiyorum = (model.year2 == "Devam Ediyor").obs;

    _showExperienceSheet(
      title: "Deneyim Düzenle",
      buttonText: "Kaydet",
      firmaAdi: firmaAdi,
      pozisyon: pozisyon,
      yil1: yil1,
      yil2: yil2,
      aciklama: aciklama,
      halenCalisiyorum: halenCalisiyorum,
      onSave: () {
        if (firmaAdi.text.trim().isEmpty || pozisyon.text.trim().isEmpty) {
          AppSnackbar("Eksik Alan", "Firma adı ve pozisyon zorunludur");
          return;
        }
        if (yil1.text.isNotEmpty && !_validateYear(yil1.text)) {
          AppSnackbar("Hata", "Geçerli bir başlangıç yılı girin");
          return;
        }
        if (yil2.text.isNotEmpty && !_validateYear(yil2.text)) {
          AppSnackbar("Hata", "Geçerli bir ayrılış yılı girin");
          return;
        }
        isDeneyimleri[index] = CVExperinceModel(
          company: firmaAdi.text.trim(),
          position: pozisyon.text.trim(),
          year1: yil1.text.trim(),
          year2: halenCalisiyorum.value ? "Devam Ediyor" : yil2.text.trim(),
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
              _textFieldBox(firmaAdi, "Firma Adı"),
              SizedBox(height: 15),
              _textFieldBox(pozisyon, "Pozisyon"),
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
                    hintText: "Görev Tanımı (opsiyonel)",
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
                              hintText: "Başlangıç",
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
                                    ? "Devam Ediyor"
                                    : "Ayrılış",
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
                              Text("Hâlen çalışıyorum",
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

  Future<void> referansEkle() async {
    TextEditingController adsoyad = TextEditingController();
    TextEditingController telefon = TextEditingController();

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
                Text("Yeni Referans Ekle",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold")),
                TextButton(
                  onPressed: () {
                    if (adsoyad.text.trim().isEmpty) {
                      AppSnackbar("Eksik Alan", "Ad soyad boş bırakılamaz");
                      return;
                    }
                    String raw = telefon.text.replaceAll(RegExp(r'[^0-9]'), '');
                    String formatted = _formatPhoneNumber(raw);
                    referanslar.add(CVReferenceHumans(
                        nameSurname: adsoyad.text.trim(), phone: formatted));
                    Get.back();
                  },
                  child: Text("Ekle",
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontFamily: "MontserratBold")),
                ),
              ],
            ),
            _textFieldBox(adsoyad, "Ad Soyad"),
            SizedBox(height: 15),
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: telefon,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  hintText: "Telefon (ör, 05xx..)",
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
            SizedBox(height: 15),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void referansDuzenle(int index) {
    final model = referanslar[index];
    TextEditingController adsoyad =
        TextEditingController(text: model.nameSurname);
    TextEditingController telefon = TextEditingController(
        text: model.phone.replaceAll(RegExp(r'[^0-9]'), ''));

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
                Text("Referans Düzenle",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold")),
                TextButton(
                  onPressed: () {
                    if (adsoyad.text.trim().isEmpty) {
                      AppSnackbar("Eksik Alan", "Ad soyad boş bırakılamaz");
                      return;
                    }
                    String raw = telefon.text.replaceAll(RegExp(r'[^0-9]'), '');
                    String formatted = _formatPhoneNumber(raw);
                    referanslar[index] = CVReferenceHumans(
                        nameSurname: adsoyad.text.trim(), phone: formatted);
                    referanslar.refresh();
                    Get.back();
                  },
                  child: Text("Kaydet",
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontFamily: "MontserratBold")),
                ),
              ],
            ),
            _textFieldBox(adsoyad, "Ad Soyad"),
            SizedBox(height: 15),
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: telefon,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(11),
                ],
                decoration: InputDecoration(
                  hintText: "Telefon (ör, 05xx..)",
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
            SizedBox(height: 15),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Skills ──

  Future<void> beceriEkle() async {
    TextEditingController beceri = TextEditingController();

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
                Text("Yeni Beceri Ekle",
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: "MontserratBold")),
                TextButton(
                  onPressed: () {
                    final text = beceri.text.trim();
                    if (text.isEmpty) {
                      AppSnackbar("Eksik Alan", "Beceri adı boş bırakılamaz");
                      return;
                    }
                    if (skills.contains(text)) {
                      AppSnackbar("Uyarı", "Bu beceri zaten eklenmiş");
                      return;
                    }
                    skills.add(text);
                    Get.back();
                  },
                  child: Text("Ekle",
                      style: TextStyle(
                          color: Colors.blueAccent,
                          fontFamily: "MontserratBold")),
                ),
              ],
            ),
            _textFieldBox(beceri, "Beceri (ör. Flutter, Photoshop)"),
            SizedBox(height: 15),
            Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map((s) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.blueAccent.withAlpha(20),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(s,
                                style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: "MontserratMedium",
                                    color: Colors.blueAccent)),
                          ))
                      .toList(),
                )),
            SizedBox(height: 15),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  // ── Helpers ──

  String _formatPhoneNumber(String raw) {
    if (raw.length == 11 && raw.startsWith("0")) {
      return "0 (${raw.substring(1, 4)}) ${raw.substring(4, 7)} ${raw.substring(7)}";
    } else if (raw.startsWith("90") && raw.length >= 12) {
      final cleaned = raw.substring(2);
      return "0 (${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)} ${cleaned.substring(6)}";
    }
    return raw;
  }

  Widget _textFieldBox(TextEditingController ctrl, String hint) {
    return Container(
      height: 50,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextField(
        controller: ctrl,
        keyboardType: TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              TextStyle(color: Colors.grey, fontFamily: "MontserratMedium"),
          border: InputBorder.none,
        ),
        style: TextStyle(
            color: Colors.black, fontSize: 15, fontFamily: "MontserratMedium"),
      ),
    );
  }

  // ── Data Operations ──

  Future<void> setData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      AppSnackbar("Hata", "Oturum açık değil.");
      return;
    }
    if (isSaving.value) return;
    isSaving.value = true;
    try {
      final payload = {
        "firstName": firstName.text.trim(),
        "lastName": lastName.text.trim(),
        "mail": mail.text.trim(),
        "phone": phoneNumber.text.trim(),
        "linkedin": linkedin.text.trim(),
        "about": onYazi.text.trim(),
        "okullar": okullar.map((e) => e.toMap()).toList(),
        "diller": diler.map((e) => e.toMap()).toList(),
        "deneyim": isDeneyimleri.map((e) => e.toMap()).toList(),
        "referans": referanslar.map((e) => e.toMap()).toList(),
        "skills": skills.toList(),
        "findingJob": false,
      };
      await FirebaseFirestore.instance.collection("CV").doc(uid).set(payload);
      await _cvRepository.setCv(uid, payload);
      selection.value = 0;
      Get.back();
      AppSnackbar("CV Oluşturuldu!",
          "Şimdi iş başvurusu yaparken daha hızlı bir şekilde başvurabilirsin");
    } catch (e) {
      AppSnackbar("Hata", "CV kaydedilemedi. Tekrar deneyin.");
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> loadDataFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final data = await _cvRepository.getCv(uid, preferCache: true);
      if (data != null) {
        firstName.text = data["firstName"] ?? "";
        lastName.text = data["lastName"] ?? "";
        mail.text = data["mail"] ?? "";
        phoneNumber.text = data["phone"] ?? "";
        linkedin.text = data["linkedin"] ?? "";
        onYazi.text = data["about"] ?? "";

        okullar.value = (data["okullar"] as List<dynamic>? ?? [])
            .map((e) => CvSchoolModel.fromMap(e))
            .toList();
        diler.value = (data["diller"] as List<dynamic>? ?? [])
            .map((e) => CVLanguegeModel.fromMap(e))
            .toList();
        isDeneyimleri.value = (data["deneyim"] as List<dynamic>? ?? [])
            .map((e) => CVExperinceModel.fromMap(e))
            .toList();
        referanslar.value = (data["referans"] as List<dynamic>? ?? [])
            .map((e) => CVReferenceHumans.fromMap(e))
            .toList();
        skills.value = (data["skills"] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList();
      }
    } catch (_) {
    }
  }

  Future<void> loadFromModel(CvModel model) async {
    firstName.text = model.firstName;
    lastName.text = model.lastName;
    mail.text = model.mail;
    phoneNumber.text = model.phone;
    linkedin.text = model.linkedin;
    onYazi.text = model.about;

    okullar.value = model.schools;
    diler.value = model.languages;
    isDeneyimleri.value = model.experiences;
    referanslar.value = model.references;
    skills.value = model.skills.toList();
  }

  void okulSil(int index) {
    okullar.removeAt(index);
  }
}
