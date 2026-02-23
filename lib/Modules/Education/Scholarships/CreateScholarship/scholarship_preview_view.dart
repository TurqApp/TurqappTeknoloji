import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Scholarships/CreateScholarship/create_scholarship_controller.dart';
import 'package:turqappv2/Themes/app_colors.dart';
import 'dart:io';

import 'package:turqappv2/Utils/empty_padding.dart';

class ScholarshipPreviewView extends StatelessWidget {
  const ScholarshipPreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<CreateScholarshipController>();
    final CarouselSliderController carouselController =
        CarouselSliderController();
    final currentIndex = 0.obs;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(text: "Burs Önizleme"),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: Obx(
                  () => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Visual Section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(8),
                        // Görsel Bilgiler bölümü
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(child: Divider()),
                                Text("  Görsel Bilgiler  ",
                                    style: TextStyles.bold20Black),
                                Expanded(child: Divider()),
                              ],
                            ),
                            12.ph,
                            Obx(() {
                              List<Widget> imageWidgets = [];

                              // Template Image
                              if (controller.selectedTemplateIndex.value !=
                                  -1) {
                                imageWidgets.add(
                                  RepaintBoundary(
                                    key: controller.templateKey,
                                    child: AspectRatio(
                                      aspectRatio: 4 / 3,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          Image.asset(
                                            'assets/bursSablonlar/${controller.selectedTemplateIndex.value + 1}.webp',
                                            fit: BoxFit.cover,
                                          ),
                                          if (controller
                                              .bursVeren.value.isNotEmpty)
                                            Positioned(
                                              top: 65,
                                              left: 15,
                                              child: Obx(() {
                                                final bursVerenKelimeler =
                                                    controller.bursVeren.value
                                                        .split(' ');
                                                final tumKelimeler = [
                                                  ...bursVerenKelimeler,
                                                  'BURS',
                                                  'BAŞVURULARI',
                                                ];

                                                return Text(
                                                  tumKelimeler.join('\n'),
                                                  style: TextStyles
                                                      .textFieldTitle
                                                      .copyWith(
                                                    color: Colors.white,
                                                    fontSize: 26,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textHeightBehavior:
                                                      TextHeightBehavior(
                                                    applyHeightToFirstAscent:
                                                        false,
                                                    applyHeightToLastDescent:
                                                        false,
                                                  ),
                                                );
                                              }),
                                            ),
                                          if (controller.logo.value.isNotEmpty)
                                            Positioned(
                                              top: 70,
                                              right: 12,
                                              child: controller.logo.value
                                                      .startsWith('http')
                                                  ? Image.network(
                                                      controller.logo.value,
                                                      width: 133,
                                                      height: 133,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                              error,
                                                              stackTrace) =>
                                                          const Icon(
                                                              Icons.error),
                                                    )
                                                  : Image.file(
                                                      File(controller
                                                          .logo.value),
                                                      width: 133,
                                                      height: 133,
                                                      fit: BoxFit.cover,
                                                    ),
                                            ),
                                          if (controller
                                              .website.value.isNotEmpty)
                                            Positioned(
                                              bottom: 6,
                                              left: 20,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    CupertinoIcons.globe,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  SizedBox(width: 4),
                                                  Text(
                                                    controller.website.value,
                                                    style: TextStyles
                                                        .textFieldTitle
                                                        .copyWith(
                                                      color: Colors.white,
                                                      fontSize: 15,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }

                              // Custom Image
                              if (controller.customImagePath.value.isNotEmpty) {
                                imageWidgets.add(
                                  AspectRatio(
                                    aspectRatio: 4 / 3,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: controller.customImagePath.value
                                              .startsWith('http')
                                          ? Image.network(
                                              controller.customImagePath.value,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error,
                                                      stackTrace) =>
                                                  const Icon(Icons.error),
                                            )
                                          : Image.file(
                                              File(controller
                                                  .customImagePath.value),
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                  ),
                                );
                              }

                              if (imageWidgets.isEmpty) {
                                return AspectRatio(
                                  aspectRatio: 4 / 3,
                                  child: Center(
                                    child: Text(
                                      "Görsel Bulunamadı",
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return Stack(
                                alignment: Alignment.center,
                                children: [
                                  CarouselSlider(
                                    carouselController: carouselController,
                                    options: CarouselOptions(
                                      aspectRatio: 4 / 3,
                                      autoPlay: false,
                                      enlargeCenterPage: true,
                                      enableInfiniteScroll:
                                          imageWidgets.length > 1,
                                      viewportFraction: 1.0,
                                      padEnds: false,
                                      onPageChanged: (index, reason) {
                                        currentIndex.value = index;
                                      },
                                    ),
                                    items: imageWidgets,
                                  ),
                                  if (imageWidgets.length > 1)
                                    Positioned(
                                      left: 10,
                                      child: GestureDetector(
                                        onTap: () {
                                          carouselController.previousPage(
                                            duration:
                                                Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            CupertinoIcons.chevron_left,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (imageWidgets.length > 1)
                                    Positioned(
                                      right: 10,
                                      child: GestureDetector(
                                        onTap: () {
                                          carouselController.nextPage(
                                            duration:
                                                Duration(milliseconds: 300),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: Container(
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color:
                                                Colors.black.withValues(alpha: 0.5),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            CupertinoIcons.chevron_right,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (imageWidgets.length > 1)
                                    Positioned(
                                      bottom: 10,
                                      left: 0,
                                      right: 0,
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: imageWidgets
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          return GestureDetector(
                                            onTap: () => carouselController
                                                .animateToPage(entry.key),
                                            child: Container(
                                              width: 8.0,
                                              height: 8.0,
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 4.0),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: currentIndex.value ==
                                                        entry.key
                                                    ? Colors.white
                                                    : Colors.white
                                                        .withValues(alpha: 0.4),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                ],
                              );
                            }),
                          ],
                        ),
                      ),
                      16.ph,
                      // Basic Details Section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(child: Divider()),
                                Text("  Temel Bilgiler  ",
                                    style: TextStyles.bold20Black),
                                Expanded(child: Divider()),
                              ],
                            ),
                            12.ph,
                            _buildInfoRow("Başlık", controller.baslik.value),
                            _buildInfoRow(
                              "Burs Veren",
                              controller.bursVeren.value,
                            ),
                            _buildInfoRow(
                              "Web Sitesi",
                              controller.website.value,
                            ),
                            _buildInfoRow(
                              "Açıklama",
                              controller.aciklama.value,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Application Details Section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(child: Divider()),
                                Text("  Başvuru Bilgileri  ",
                                    style: TextStyles.bold20Black),
                                Expanded(child: Divider()),
                              ],
                            ),
                            12.ph,
                            _buildInfoRow(
                              "Başvuru Koşulları",
                              controller.basvuruKosullari.value,
                            ),
                            _buildInfoRow(
                              "Başvuru URL",
                              controller.basvuruURL.value,
                            ),
                            _buildInfoRow(
                              "Başvuru Yapılacak Yer",
                              controller.basvuruYapilacakYer.value,
                            ),
                            _buildInfoRow(
                              "Başlangıç Tarihi",
                              controller.baslangicTarihi.value,
                            ),
                            _buildInfoRow(
                              "Bitiş Tarihi",
                              controller.bitisTarihi.value,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16),
                      // Additional Details Section
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 2,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(child: Divider()),
                                Text("  Ek Bilgiler  ",
                                    style: TextStyles.bold20Black),
                                Expanded(child: Divider()),
                              ],
                            ),
                            12.ph,
                            _buildInfoRow(
                              "Tutar",
                              "${controller.tutar.value} ₺",
                            ),
                            _buildInfoRow(
                              "Öğrenci Sayısı",
                              controller.ogrenciSayisi.value,
                            ),
                            _buildInfoRow(
                              "Geri Ödemeli",
                              controller.geriOdemeli.value,
                            ),
                            _buildInfoRow(
                              "Mükerrer Durumu",
                              controller.mukerrerDurumu.value,
                            ),
                            _buildInfoRow(
                              "Eğitim Kitlesi",
                              controller.egitimKitlesi.value,
                            ),
                            _buildInfoRow(
                              "Hedef Kitle",
                              controller.hedefKitle.value,
                            ),
                            _buildInfoRow(
                              "Ülke",
                              controller.ulke.value,
                            ),
                            _buildInfoRow(
                              "Şehirler",
                              controller.sehirler.join(", "),
                            ),
                            _buildInfoRow(
                              "Üniversiteler",
                              controller.universiteler.join(", "),
                            ),
                            _buildInfoRow(
                              "Belgeler",
                              controller.belgeler.join(", "),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 20),
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => Get.back(),
                              child: Container(
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withValues(alpha: 0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Geri',
                                  style: TextStyles.textFieldTitle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textBlack,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              // Mevcut onTap bloğunu bu şekilde değiştirin:
                              onTap: () async {
                                // Eğer şu anki slide 0 değilse, önce ilk slayda geç
                                if (currentIndex.value != 0) {
                                  await carouselController.animateToPage(
                                    0,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOut,
                                  );
                                }
                                // Sonra share/update işlemlerini başlat
                                controller.isLoading.value = true;
                                if (controller.isEditing.value) {
                                  await controller.updateScholarship();
                                } else {
                                  await controller.saveScholarship();
                                }
                                controller.isLoading.value = false;
                              },

                              child: Container(
                                height: 50,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.textBlack,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Obx(() {
                                  return controller.isLoading.value
                                      ? CupertinoActivityIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          controller.isEditing.value
                                              ? 'Güncelle'
                                              : 'Paylaş',
                                          style: TextStyles.medium15white
                                              .copyWith(fontSize: 16),
                                        );
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyles.textFieldTitle.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textBlack,
            ),
          ),
          4.ph,
          Text(
            value.isEmpty ? "Belirtilmemiş" : value,
            style: TextStyles.textFieldTitle.copyWith(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
