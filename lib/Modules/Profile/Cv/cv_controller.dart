import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Models/CVModels/school_model.dart';

class CvController extends GetxController {
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

  @override
  void onInit() {
    super.onInit();
    loadDataFromFirestore();
  }

  Future<void> okulEkle() async {
    TextEditingController okul = TextEditingController();
    TextEditingController bolum = TextEditingController();
    TextEditingController yil = TextEditingController();

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.height / 2, // ✅ Yükseklik sınırı
        ),
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
                    okullar.add(CvSchoolModel(school: okul.text, branch: bolum.text, lastYear: yil.text));
                    Get.back();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Text(
                          "Ekle",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius:
                BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15),
                child: TextField(
                  controller: okul,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: "Okul Adı",
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
            SizedBox(height: 15,),
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius:
                BorderRadius.all(Radius.circular(12)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15),
                child: TextField(
                  controller: bolum,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    hintText: "Bölüm",
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
            SizedBox(height: 15,),
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
                  // 📆 Mezuniyet Yılı TextField
                  Expanded(
                    child: TextField(
                      controller: yil,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(4),
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


                  Row(
                    children: [
                      if (yil.text != "Halen")
                        GestureDetector(
                          onTap: () {
                            yil.text = "Halen";
                          },
                          child: Text(
                            "Hâlen Devam Ediyorum",
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 14,
                              fontFamily: "MontserratMedium",
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: 15,),
          ],
        )
      ),
      isScrollControlled: true,
    );
  }

  Future<void> dilEkle() async {
    RxString selectedDil = ''.obs;
    RxInt selectedSeviye = 3.obs;

    final List<String> ornekdiller = [
      "İngilizce", "Almanca", "Fransızca",
      "İspanyolca", "Arapça", "Türkçe",
      "Rusça", "İtalyanca", "Korece",
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
            // Başlık ve Ekle butonu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Yeni Dil Ekle",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
                Obx(() => TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: selectedDil.value.isEmpty
                      ? null
                      : () {
                    diler.add(CVLanguegeModel(languege: selectedDil.value, level: selectedSeviye.toInt(), index: diler.length + 10000));
                    Get.back();
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "Ekle",
                      style: TextStyle(
                        color: selectedDil.value.isEmpty ? Colors.grey : Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratBold",
                      ),
                    ),
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
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blueAccent : Colors.grey.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dil,
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
            )),

            const SizedBox(height: 20),


            Text(
              "Seviye",
              style: TextStyle(
                fontFamily: "MontserratMedium",
                fontSize: 14,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Row(
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => selectedSeviye.value = index + 1,
                  child: Icon(
                    index < selectedSeviye.value ? CupertinoIcons.star_fill : CupertinoIcons.star,
                    color: index < selectedSeviye.value ? Colors.amber : Colors.grey,
                    size: 28,
                  ),
                );
              }),
            )),
            SizedBox(height: 25,),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> isDeneyimiEkle() async {
    TextEditingController firmaAdi = TextEditingController();
    TextEditingController pozisyon = TextEditingController();
    TextEditingController yil1 = TextEditingController();
    TextEditingController yil2 = TextEditingController();

    RxBool halenCalisiyorum = false.obs;

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
            // Başlık ve Ekle Butonu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Yeni İş Deneyimi Ekle",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Get.back();
                    isDeneyimleri.add(CVExperinceModel(company: firmaAdi.text, position: pozisyon.text, year1: yil1.text, year2: yil2.text));
                  },
                  child: Text(
                    "Ekle",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                )
              ],
            ),

            SizedBox(height: 15),

            // Firma Adı
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: firmaAdi,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: "Firma Adı",
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

            SizedBox(height: 15),

            // Pozisyon
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: pozisyon,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: "Pozisyon",
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

            SizedBox(height: 15),

            // Başlangıç ve Ayrılış Yılı
            Obx(() => Row(
              children: [
                // Başlangıç
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
                ),

                SizedBox(width: 12),

                // Ayrılış
                Expanded(
                  child: Opacity(
                    opacity: halenCalisiyorum.value ? 0.4 : 1.0, // 👈 Opaklık kontrolü
                    child: Container(
                      height: 50,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
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
                          hintText: halenCalisiyorum.value ? "Devam Ediyor" : "Ayrılış",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontStyle: !halenCalisiyorum.value ? FontStyle.normal : FontStyle.italic,
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
                  ),
                ),
              ],
            )),

            // Hâlen Çalışıyorum Butonu
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Obx(() => Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: GestureDetector(
                    onTap: () {
                      halenCalisiyorum.toggle();
                      if (halenCalisiyorum.value) {
                        yil2.clear();
                      }
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 25,
                          height: 25,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(Radius.circular(4)),
                              color: halenCalisiyorum.value ? Colors.black : Colors.transparent,
                              border: Border.all(color: Colors.black)
                          ),
                          child: Icon(
                            CupertinoIcons.checkmark,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        SizedBox(width: 7,),
                        Text(
                          "Hâlen çalışıyorum",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 14,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
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
      isScrollControlled: true,
    );
  }

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
            // Başlık ve Ekle Butonu
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Yeni Referans Ekle",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                    fontFamily: "MontserratBold",
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // Telefonu formatlı şekilde ekle
                    String raw = telefon.text.replaceAll(RegExp(r'[^0-9]'), '');
                    String formatted = raw;
                    if (raw.length == 11 && raw.startsWith("0")) {
                      formatted =
                      "0 (${raw.substring(1, 4)}) ${raw.substring(4, 7)} ${raw.substring(7)}";
                    } else if (raw.startsWith("90") && raw.length >= 12) {
                      final cleaned = raw.substring(2);
                      formatted =
                      "0 (${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)} ${cleaned.substring(6)}";
                    }

                    referanslar.add(CVReferenceHumans(
                      nameSurname: adsoyad.text,
                      phone: formatted,
                    ));
                    Get.back();
                  },
                  child: Text(
                    "Ekle",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontFamily: "MontserratBold",
                    ),
                  ),
                )
              ],
            ),

            // Ad Soyad
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: TextField(
                controller: adsoyad,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: "Ad Soyad",
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

            SizedBox(height: 15),

            // Telefon
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

            SizedBox(height: 15),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Future<void> setData() async {
    await FirebaseFirestore.instance
        .collection("CV")
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .set({
      "firstName": firstName.text,
      "lastName": lastName.text,
      "mail": mail.text,
      "phone": phoneNumber.text,
      "linkedin": linkedin.text,
      "about": onYazi.text,
      "okullar": okullar.map((e) => e.toMap()).toList(),
      "diller": diler.map((e) => e.toMap()).toList(),
      "deneyim": isDeneyimleri.map((e) => e.toMap()).toList(),
      "referans": referanslar.map((e) => e.toMap()).toList(),
      "findingJob" : false,
    });
    selection.value = 0;
    Get.back();
    AppSnackbar("CV Oluşturuldu!", "Şimdi iş başvurusu yaparken daha hızlı bir şekilde başvurabilirsin");
  }

  Future<void> loadDataFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection("CV").doc(uid).get();

    if (doc.exists) {
      final data = doc.data()!;
      final model = CvModel(
        firstName: data["firstName"] ?? "",
        lastName: data["lastName"] ?? "",
        mail: data["mail"] ?? "",
        phone: data["phone"] ?? "",
        linkedin: data["linkedin"] ?? "",
        about: data["about"] ?? "",
        schools: (data["okullar"] as List<dynamic>).map((e) => CvSchoolModel.fromMap(e)).toList(),
        languages: (data["diller"] as List<dynamic>).map((e) => CVLanguegeModel.fromMap(e)).toList(),
        experiences: (data["deneyim"] as List<dynamic>).map((e) => CVExperinceModel.fromMap(e)).toList(),
        references: (data["referans"] as List<dynamic>).map((e) => CVReferenceHumans.fromMap(e)).toList(),
          findingJob: data["findingJob"]
      );

      loadFromModel(model);
    }
  }

  Future<void> loadFromModel(CvModel model)  async {
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
  }

  void okulSil(int index) {
    okullar.removeAt(index);
  }
}