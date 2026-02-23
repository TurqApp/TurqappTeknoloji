import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Modules/Profile/Cv/cv_controller.dart';

class Cv extends StatelessWidget {
  final CvController controller = Get.put(CvController());

  Cv({super.key});
  @override
  Widget build(BuildContext context) {
    controller.selection.value = 0;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Obx(() {
            return Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (controller.selection.value == 0) {
                              Get.back();
                            } else {
                              controller.selection.value--;
                            }
                          },
                          icon: Icon(
                            CupertinoIcons.arrow_left,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          controller.selection.value == 0
                              ? "Kişisel Bilgiler"
                              : controller.selection.value == 1
                                  ? "Eğitim Bilgileri"
                                  : controller.selection.value == 2
                                      ? "Diğer Bilgiler"
                                      : "",
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontFamily: "MontserratBold"),
                        )
                      ],
                    ),
                    Obx(() {
                      return TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          if (controller.selection.value == 0) {
                            if (controller.firstName.text == "") {
                              AppSnackbar("Eksik Alan",
                                  "İsim girmeden devam edemezsiniz");
                            } else if (controller.lastName.text == "") {
                              AppSnackbar("Eksik Alan",
                                  "Soyisim girmeden devam edemezsiniz");
                            } else if (controller.mail.text == "") {
                              AppSnackbar("Eksik Alan",
                                  "Mail adresi girmeden devam edemezsiniz");
                            } else if (controller.phoneNumber.text == "") {
                              AppSnackbar("Eksik Alan",
                                  "Telefon numarası girmeden devam edemezsiniz");
                            } else if (controller.onYazi.text == "") {
                              AppSnackbar("Eksik Alan",
                                  "Kendiniz hakkında kısa bilgi vermek zorundasınız");
                            } else {
                              controller.selection.value++;
                            }
                          } else if (controller.selection.value == 1) {
                            if (controller.okullar.isEmpty) {
                              AppSnackbar("Eksik Alan",
                                  "En az bir okul bilgisi girmeden devam edemezsiniz");
                            } else {
                              controller.selection.value++;
                            }
                          } else {
                            controller.setData();
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Text(
                                controller.selection.value != 2
                                    ? "Devam"
                                    : "Tamamla",
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold",
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: controller.selection.value == 0
                        ? step1()
                        : controller.selection.value == 1
                            ? step2()
                            : step3())
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget step1() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    controller: controller.firstName,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-zÇçĞğİıÖöŞşÜü\s]'),
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: "Adınız",
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
              ),
            ),
            SizedBox(
              width: 12,
            ),
            Expanded(
              child: Container(
                height: 50,
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: TextField(
                    controller: controller.lastName,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(30),
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[A-Za-zÇçĞğİıÖöŞşÜü\s]'),
                      ),
                    ],
                    decoration: InputDecoration(
                      hintText: "Soyadınız",
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
              ),
            ),
          ],
        ),
        SizedBox(
          height: 15,
        ),
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: controller.mail,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Mail Adresi",
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
        ),
        SizedBox(
          height: 15,
        ),
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: controller.phoneNumber,
              keyboardType: TextInputType.number,
              // inputFormatters eklendi:
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, // Sadece rakam
                LengthLimitingTextInputFormatter(10), // En fazla 10 karakter
              ],
              decoration: InputDecoration(
                hintText: "Telefon Numarası",
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
        ),
        SizedBox(
          height: 15,
        ),
        Container(
          height: 50,
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: TextField(
              controller: controller.linkedin,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                hintText: "Linkedin adresi",
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
        ),
        SizedBox(
          height: 15,
        ),
        Container(
          height: 150,
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.03),
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
          child: TextField(
            controller: controller.onYazi,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.done,
            maxLines: null,
            maxLength: 250,
            expands: true, // ⚠️ Bu satır alanı tamamen kullanmasını sağlar
            decoration: InputDecoration(
              hintText: "Kendiniz hakkında kısa bilgi verin",
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: "MontserratMedium",
              ),
              border: InputBorder.none,
              isDense: true, // padding'i sadeleştirir
              contentPadding:
                  EdgeInsets.zero, // iç boşluğu sıfırlar, Container’dan gelir
            ),
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontFamily: "MontserratMedium",
            ),
          ),
        ),
      ],
    );
  }

  Widget step2() {
    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.okullar.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.okullar.length) {
              // Ekle butonu
              return GestureDetector(
                onTap: () => controller.okulEkle(),
                child: Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        "Yeni okul ekle",
                        style: TextStyle(
                          fontFamily: "MontserratMedium",
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // HER BİR OKUL
            final model = controller.okullar[index];
            return Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(20),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              model.school,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratBold",
                              ),
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Row(
                              children: [
                                Text(
                                  model.branch,
                                  style: TextStyle(
                                    color: Colors.pinkAccent,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 3),
                                  child: Text("-"),
                                ),
                                Text(
                                  model.lastYear,
                                  style: TextStyle(
                                    color: Colors.pinkAccent,
                                    fontSize: 15,
                                    fontFamily: "MontserratMedium",
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: GestureDetector(
                    onTap: () {
                      controller.okulSil(index);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
                      child:
                          Icon(Icons.close, size: 18, color: Colors.redAccent),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget step3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 12,
        ),
        Row(
          children: [
            Text(
              "Dil Ekle",
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount:
              controller.diler.length >= 5 ? 5 : controller.diler.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.diler.length &&
                controller.diler.length < 5) {
              return GestureDetector(
                onTap: () => controller.dilEkle(),
                child: Container(
                  margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        "Yeni dil ekle",
                        style: TextStyle(
                          fontFamily: "MontserratMedium",
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final model = controller.diler[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.languege,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (i) {
                            return Icon(
                              i < model.level ? Icons.star : Icons.star_border,
                              color:
                                  i < model.level ? Colors.amber : Colors.grey,
                              size: 20,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.diler.removeAt(index),
                    child: Icon(CupertinoIcons.trash,
                        color: Colors.redAccent, size: 20),
                  )
                ],
              ),
            );
          },
        ),
        Row(
          children: [
            Text(
              "İş Deneyimi Ekle",
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.isDeneyimleri.length >= 5
              ? 5
              : controller.isDeneyimleri.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.isDeneyimleri.length &&
                controller.isDeneyimleri.length < 5) {
              return GestureDetector(
                onTap: () => controller.isDeneyimiEkle(),
                child: Container(
                  margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        "Yeni iş deneyimi ekle",
                        style: TextStyle(
                          fontFamily: "MontserratMedium",
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final model = controller.isDeneyimleri[index];
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.position,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          model.company,
                          style: TextStyle(
                            color: Colors.pinkAccent,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          "${model.year1} - ${model.year2}",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.isDeneyimleri.removeAt(index),
                    child: Icon(CupertinoIcons.trash,
                        color: Colors.redAccent, size: 20),
                  )
                ],
              ),
            );
          },
        ),
        Row(
          children: [
            Text(
              "Referans Ekle",
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontFamily: "MontserratBold",
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: controller.referanslar.length >= 5
              ? 5
              : controller.referanslar.length + 1,
          itemBuilder: (context, index) {
            if (index == controller.referanslar.length &&
                controller.referanslar.length < 5) {
              return GestureDetector(
                onTap: () => controller.referansEkle(),
                child: Container(
                  margin: EdgeInsets.only(top: index == 0 ? 0 : 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: Colors.black),
                      SizedBox(width: 8),
                      Text(
                        "Yeni referans ekle",
                        style: TextStyle(
                          fontFamily: "MontserratMedium",
                          fontSize: 14,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final model = controller.referanslar[index];

            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          model.nameSurname,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 15,
                            fontFamily: "MontserratBold",
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          "0 (${model.phone.replaceAll("+90", "").substring(0, 3)}) ${model.phone.replaceAll("+90", "").substring(3, 6)} ${model.phone.replaceAll("+90", "").substring(6, 10)}",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 15,
                            fontFamily: "MontserratMedium",
                          ),
                        ),
                        SizedBox(height: 7),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => controller.referanslar.removeAt(index),
                    child: Icon(CupertinoIcons.trash,
                        color: Colors.redAccent, size: 20),
                  )
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
