import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import '../../../Core/LocationFinderView/location_finder_view.dart';
import '../../../Models/job_model.dart';
import 'job_creator_controller.dart';

part 'job_creator_steps_part.dart';

class JobCreator extends StatelessWidget {
  final JobModel? existingJob;
  JobCreator({super.key, this.existingJob});

  late final controller =
      Get.put(JobCreatorController(existingJob: existingJob));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Obx(() {
          return Column(
            children: [
              header(context),
              if (controller.selection.value == 0)
                step1()
              else if (controller.selection.value == 1)
                step2()
              else if (controller.selection.value == 2)
                step3(context)
            ],
          );
        }),
      ),
    );
  }

  Widget header(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 15, right: 15, top: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () {
              if (controller.selection.value == 0) {
                Get.back();
              } else {
                controller.selection.value--;
              }
            },
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.arrow_left,
                  color: Colors.black,
                ),
                SizedBox(
                  width: 12,
                ),
                Text(
                  controller.selection.value == 0
                      ? "Firma Bilgileri"
                      : controller.selection.value == 1
                          ? "Adres Bilgileri"
                          : controller.selection.value == 2
                              ? "İş Tanımı"
                              : "",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontFamily: "MontserratBold"),
                )
              ],
            ),
          ),
          Obx(() {
            return TextButton(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                if (controller.selection.value == 0) {
                  if (controller.croppedImage.value == null) {
                    AppSnackbar("Eksik alan",
                        "Firma logosu seçmeden devam edemezsiniz");
                  } else if (controller.brand.text == "") {
                    AppSnackbar("Eksik alan",
                        "Firma ismini girmeden devam edemezsiniz");
                  } else if (controller.about.text == "") {
                    AppSnackbar("Eksik alan",
                        "Firma hakkında açıklama yapmadan devam edemezsiniz");
                  } else {
                    controller.selection.value++;
                  }
                }
                if (controller.selection.value == 1) {
                  if (controller.sehir.value == "") {
                    AppSnackbar("Eksik alan",
                        "Şehir seçimi yapmadan devam edemezsiniz");
                  } else if (controller.ilce.value == "") {
                    AppSnackbar(
                        "Eksik alan", "İlçe seçimi yapmadan devam edemezsiniz");
                  } else if (controller.adres.value == "" &&
                      controller.lat.value == 0) {
                    AppSnackbar("Eksik alan",
                        "Mevcut konumunuzu kullanarak firma adresinizi belirtiniz");
                  } else {
                    controller.selection.value++;
                  }
                }
                if (controller.selection.value == 2) {
                  if (controller.selectedCalismaTuruList.isEmpty) {
                    AppSnackbar("Eksik alan",
                        "Çalışma türü seçmeden devam edemezsiniz");
                  } else if (controller.meslek.value == "") {
                    AppSnackbar(
                        "Eksik alan", "Meslek seçmeden devam edemezsiniz");
                  } else if (controller.isTanimi.text == "") {
                    AppSnackbar(
                        "Eksik alan", "İş tanımını açıklamak zorundasınız");
                  } else if (controller.selectedYanHaklar.isEmpty) {
                    AppSnackbar(
                        "Eksik alan", "En az bir yan hak eklemek zorundasın");
                  } else if (controller.maasOpen.value == true &&
                      controller.maas1.text == "") {
                    AppSnackbar("Eksik alan",
                        "Maaş belirtmek istediğiniz için bir maaş aralığı girmek zorundasınız");
                  } else if (controller.maasOpen.value == true &&
                      controller.maas2.text == "") {
                    AppSnackbar("Eksik alan",
                        "Maaş belirtmek istediğiniz için bir maaş aralığı girmek zorundasınız");
                  } else if (controller.maasOpen.value == true &&
                      controller.maas1.text.isNotEmpty &&
                      controller.maas2.text.isNotEmpty &&
                      (int.tryParse(controller.maas2.text) ?? 0) <
                          (int.tryParse(controller.maas1.text) ?? 0)) {
                    AppSnackbar("Hatalı Aralık",
                        "Maksimum maaş, minimum maaştan düşük olamaz");
                  } else if (controller.pozisyonSayisi.text.isNotEmpty &&
                      ((int.tryParse(controller.pozisyonSayisi.text) ?? 0) <
                              1 ||
                          (int.tryParse(controller.pozisyonSayisi.text) ?? 0) >
                              100)) {
                    AppSnackbar("Hatalı Değer",
                        "Pozisyon sayısı 1 ile 100 arasında olmalıdır");
                  } else {
                    controller.setData();
                  }
                }
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Text(
                      controller.selection.value != 2 ? "Devam" : "Yayınla!",
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 15,
                        fontFamily: "MontserratBold",
                      ),
                    ),
                    if (controller.selection.value != 2)
                      Padding(
                        padding: const EdgeInsets.only(left: 3),
                        child: Icon(
                          CupertinoIcons.chevron_right,
                          color: Colors.blueAccent,
                        ),
                      )
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
