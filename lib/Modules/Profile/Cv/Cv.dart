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
                                  : "Diğer Bilgiler",
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
                            if (controller.firstName.text.trim().isEmpty) {
                              AppSnackbar("Eksik Alan",
                                  "İsim girmeden devam edemezsiniz");
                            } else if (controller.lastName.text
                                .trim()
                                .isEmpty) {
                              AppSnackbar("Eksik Alan",
                                  "Soyisim girmeden devam edemezsiniz");
                            } else if (controller.mail.text.trim().isEmpty) {
                              AppSnackbar("Eksik Alan",
                                  "Mail adresi girmeden devam edemezsiniz");
                            } else if (!controller
                                .validateEmail(controller.mail.text.trim())) {
                              AppSnackbar("Hatalı Format",
                                  "Geçerli bir e-posta adresi girin");
                            } else if (controller.phoneNumber.text
                                .trim()
                                .isEmpty) {
                              AppSnackbar("Eksik Alan",
                                  "Telefon numarası girmeden devam edemezsiniz");
                            } else if (!controller
                                .validatePhone(controller.phoneNumber.text)) {
                              AppSnackbar("Hatalı Format",
                                  "Geçerli bir telefon numarası girin");
                            } else if (controller.onYazi.text.trim().isEmpty) {
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
                            if (!controller.isSaving.value) {
                              controller.setData();
                            }
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              if (controller.isSaving.value)
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
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
            SizedBox(width: 12),
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
        SizedBox(height: 15),
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
        SizedBox(height: 15),
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
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(11),
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
        SizedBox(height: 15),
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
                hintText: "LinkedIn adresi (opsiyonel)",
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
        SizedBox(height: 15),
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
            expands: true,
            decoration: InputDecoration(
              hintText: "Kendiniz hakkında kısa bilgi verin",
              hintStyle: TextStyle(
                color: Colors.grey,
                fontFamily: "MontserratMedium",
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
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
                      Text("Yeni okul ekle",
                          style: TextStyle(
                              fontFamily: "MontserratMedium",
                              fontSize: 14,
                              color: Colors.black)),
                    ],
                  ),
                ),
              );
            }

            final model = controller.okullar[index];
            return Stack(
              children: [
                GestureDetector(
                  onTap: () => controller.okulDuzenle(index),
                  child: Container(
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
                              Text(model.school,
                                  style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 15,
                                      fontFamily: "MontserratBold")),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(model.branch,
                                      style: TextStyle(
                                          color: Colors.pinkAccent,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium")),
                                  if (model.branch.isNotEmpty &&
                                      model.lastYear.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 3),
                                      child: Text("-"),
                                    ),
                                  Text(model.lastYear,
                                      style: TextStyle(
                                          color: Colors.pinkAccent,
                                          fontSize: 15,
                                          fontFamily: "MontserratMedium")),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(CupertinoIcons.pencil,
                            color: Colors.grey, size: 18),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: GestureDetector(
                    onTap: () => controller.okulSil(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 3,
                              spreadRadius: 1)
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
        // ── Skills / Beceriler ──
        SizedBox(height: 12),
        Row(
          children: [
            Text("Beceriler",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratBold")),
            SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey.withAlpha(50))),
          ],
        ),
        SizedBox(height: 12),
        Obx(() => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...controller.skills.asMap().entries.map((entry) {
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.blueAccent.withAlpha(20),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(entry.value,
                            style: TextStyle(
                                fontSize: 13,
                                fontFamily: "MontserratMedium",
                                color: Colors.blueAccent)),
                        SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => controller.skills.removeAt(entry.key),
                          child: Icon(Icons.close,
                              size: 16, color: Colors.blueAccent),
                        ),
                      ],
                    ),
                  );
                }),
                if (controller.skills.length < 10)
                  GestureDetector(
                    onTap: () => controller.beceriEkle(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 16, color: Colors.black),
                          SizedBox(width: 4),
                          Text("Ekle",
                              style: TextStyle(
                                  fontSize: 13,
                                  fontFamily: "MontserratMedium",
                                  color: Colors.black)),
                        ],
                      ),
                    ),
                  ),
              ],
            )),

        SizedBox(height: 20),

        // ── Languages ──
        Row(
          children: [
            Text("Dil Ekle",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratBold")),
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
                      Text("Yeni dil ekle",
                          style: TextStyle(
                              fontFamily: "MontserratMedium",
                              fontSize: 14,
                              color: Colors.black)),
                    ],
                  ),
                ),
              );
            }

            final model = controller.diler[index];
            return GestureDetector(
              onTap: () => controller.dilDuzenle(index),
              child: Container(
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
                          Text(model.languege,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold")),
                          SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (i) {
                              return Icon(
                                i < model.level
                                    ? Icons.star
                                    : Icons.star_border,
                                color: i < model.level
                                    ? Colors.amber
                                    : Colors.grey,
                                size: 20,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.pencil, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.diler.removeAt(index),
                      child: Icon(CupertinoIcons.trash,
                          color: Colors.redAccent, size: 20),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // ── Experience ──
        Row(
          children: [
            Text("İş Deneyimi Ekle",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratBold")),
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
                      Text("Yeni iş deneyimi ekle",
                          style: TextStyle(
                              fontFamily: "MontserratMedium",
                              fontSize: 14,
                              color: Colors.black)),
                    ],
                  ),
                ),
              );
            }

            final model = controller.isDeneyimleri[index];
            return GestureDetector(
              onTap: () => controller.isDeneyimiDuzenle(index),
              child: Container(
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
                          Text(model.position,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold")),
                          SizedBox(height: 4),
                          Text(model.company,
                              style: TextStyle(
                                  color: Colors.pinkAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                          if (model.description.isNotEmpty) ...[
                            SizedBox(height: 4),
                            Text(model.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 13,
                                    fontFamily: "Montserrat")),
                          ],
                          SizedBox(height: 4),
                          Text("${model.year1} - ${model.year2}",
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.pencil, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.isDeneyimleri.removeAt(index),
                      child: Icon(CupertinoIcons.trash,
                          color: Colors.redAccent, size: 20),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        // ── References ──
        Row(
          children: [
            Text("Referans Ekle",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 15,
                    fontFamily: "MontserratBold")),
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
                      Text("Yeni referans ekle",
                          style: TextStyle(
                              fontFamily: "MontserratMedium",
                              fontSize: 14,
                              color: Colors.black)),
                    ],
                  ),
                ),
              );
            }

            final model = controller.referanslar[index];
            return GestureDetector(
              onTap: () => controller.referansDuzenle(index),
              child: Container(
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
                          Text(model.nameSurname,
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratBold")),
                          SizedBox(height: 4),
                          Text(model.phone,
                              style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium")),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(CupertinoIcons.pencil, color: Colors.grey, size: 18),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => controller.referanslar.removeAt(index),
                      child: Icon(CupertinoIcons.trash,
                          color: Colors.redAccent, size: 20),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
