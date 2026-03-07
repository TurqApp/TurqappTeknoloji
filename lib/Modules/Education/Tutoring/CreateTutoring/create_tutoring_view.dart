import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/Buttons/back_buttons.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Core/text_styles.dart';
import 'package:turqappv2/Modules/Education/Tutoring/CreateTutoring/create_tutoring_controller.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_category.dart';
import 'package:turqappv2/Utils/empty_padding.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

class CreateTutoringView extends StatelessWidget {
  const CreateTutoringView({super.key});

  @override
  Widget build(BuildContext context) {
    final CreateTutoringController controller = Get.put(
      CreateTutoringController(),
    );
    final TutoringModel? initialData = Get.arguments as TutoringModel?;

    // Başlangıç verilerini doldur
    if (initialData != null) {
      controller.titleController.text = initialData.baslik;
      controller.descriptionController.text = initialData.aciklama;
      controller.branchController.text = initialData.brans;
      controller.priceController.text = initialData.fiyat.toString();
      controller.cityController.text = initialData.sehir;
      controller.districtController.text = initialData.ilce;
      controller.selectedLessonPlace.value =
          initialData.dersYeri.isNotEmpty ? initialData.dersYeri[0] : '';
      controller.selectedGender.value = initialData.cinsiyet;
      controller.city.value = initialData.sehir;
      controller.town = initialData.ilce;
      controller.isPhoneOpen.value = initialData.telefon;
      controller.selectedBranch.value = initialData.brans;
      if (initialData.imgs != null && initialData.imgs!.isNotEmpty) {
        controller.images.assignAll(
          initialData.imgs!,
        ); // URL'leri direkt atıyoruz
      }
      if (initialData.availability != null) {
        controller.availability.assignAll(initialData.availability!);
      }
    }

    Widget buildTextField(
      String label,
      TextEditingController controller, {
      String? hint,
      int maxLines = 1,
      TextInputType? keyboardType,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyles.textFieldTitle),
          8.ph,
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint ?? label,
              filled: true,
              fillColor: Colors.grey.shade200,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 16,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      );
    }

    Widget buildLocationSelector(CreateTutoringController controller) {
      return Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Hizmet Verilen Yer", style: TextStyles.textFieldTitle),
            8.ph,
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: controller.showIlSec,
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
                        padding: const EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              controller.city.value.isEmpty
                                  ? "Şehir Seç"
                                  : controller.city.value,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 15,
                                fontFamily: "MontserratMedium",
                              ),
                            ),
                            const Icon(CupertinoIcons.chevron_down, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (controller.city.value.isNotEmpty) const SizedBox(width: 12),
                if (controller.city.value.isNotEmpty)
                  Expanded(
                    child: GestureDetector(
                      onTap: controller.showIlcelerSec,
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
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                controller.town.isEmpty
                                    ? "İlçe Seç"
                                    : controller.town,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 15,
                                  fontFamily: "MontserratMedium",
                                ),
                              ),
                              const Icon(CupertinoIcons.chevron_down, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    Widget buildSelectionField(
      String label,
      RxString selectedValue,
      List<String> options, {
      String hint = "Seçin",
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyles.textFieldTitle),
          8.ph,
          GestureDetector(
            onTap: () {
              AppBottomSheet.show(
                context: context,
                items: options,
                title: label,
                onSelect: (value) => selectedValue.value = value,
                selectedItem: selectedValue.value,
              );
            },
            child: Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(
                    () => Text(
                      selectedValue.value.isEmpty ? hint : selectedValue.value,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontFamily: "MontserratMedium",
                      ),
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      );
    }

    Widget buildCategorySelection(CreateTutoringController controller) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Branş", style: TextStyles.textFieldTitle),
          8.ph,
          GestureDetector(
            onTap: () {
              Get.bottomSheet(
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(25),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        height: 4,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      12.ph,
                      Text("Branş Seç", style: TextStyles.bold18Black),
                      16.ph,
                      GridView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1,
                        ),
                        itemCount: kategoriler.length,
                        itemBuilder: (context, index) {
                          final category = kategoriler[index];
                          return GestureDetector(
                            onTap: () {
                              controller.selectedBranch.value = category.name;
                              Get.back();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: category.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: category.color.withValues(alpha: 0.5),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    category.icon,
                                    color: category.color,
                                    size: 30,
                                  ),
                                  4.ph,
                                  Text(
                                    category.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: category.color,
                                      fontSize: 12,
                                      fontFamily: "MontserratMedium",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
            child: Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Obx(
                      () => Text(
                        controller.selectedBranch.value.isEmpty
                            ? "Branş Seç"
                            : controller.selectedBranch.value,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontFamily: "MontserratMedium",
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_down, size: 20),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            BackButtons(
              text: initialData != null ? "İlanı Düzenle" : "Özel Ders Oluştur",
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Form(
                  key: controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Görsel Ekle", style: TextStyles.textFieldTitle),
                      8.ph,
                      GestureDetector(
                        onTap: () async {
                          final pickedFiles =
                              await AppImagePickerService.pickImages(
                            context,
                            maxAssets: 10,
                          );
                          if (pickedFiles.isNotEmpty) {
                            controller.images.clear(); // Eski resimleri temizle
                            for (var imageFile in pickedFiles) {
                              final r = await OptimizedNSFWService.checkImage(
                                imageFile,
                              );
                              if (r.isNSFW) {
                                AppSnackbar(
                                  "Yükleme Başarısız!",
                                  "Bu içerik şu anda işlenemiyor. Lütfen başka bir içerik deneyin.",
                                  backgroundColor:
                                      Colors.red.withValues(alpha: 0.7),
                                );
                              } else {
                                controller.addImage(imageFile.path);
                              }
                            }
                          }
                        },
                        child: Container(
                          width: Get.width,
                          height: Get.width,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Obx(
                            () => controller.images.isEmpty
                                ? Center(
                                    child: Icon(
                                      Icons.add_a_photo,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  )
                                : Stack(
                                    alignment: Alignment.bottomCenter,
                                    children: [
                                      PageView.builder(
                                        itemCount: controller.images.length,
                                        onPageChanged: (index) {
                                          controller.carouselCurrentIndex
                                              .value = index;
                                        },
                                        itemBuilder: (context, index) =>
                                            ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: controller.images[index]
                                                  .startsWith('http')
                                              ? CachedNetworkImage(
                                                  imageUrl:
                                                      controller.images[index],
                                                  placeholder: (context, url) =>
                                                      CupertinoActivityIndicator(),
                                                  errorWidget: (
                                                    context,
                                                    url,
                                                    error,
                                                  ) =>
                                                      Icon(
                                                    CupertinoIcons.photo,
                                                  ),
                                                  fit: BoxFit.cover,
                                                )
                                              : Image.file(
                                                  File(
                                                    controller.images[index],
                                                  ),
                                                  height: Get.width,
                                                  width: Get.width,
                                                  fit: BoxFit.cover,
                                                ),
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: controller.images
                                            .asMap()
                                            .entries
                                            .map((
                                          entry,
                                        ) {
                                          return Container(
                                            width: 8,
                                            height: 8,
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: Colors.grey.withValues(
                                                alpha: controller
                                                            .carouselCurrentIndex
                                                            .value ==
                                                        entry.key
                                                    ? 0.9
                                                    : 0.4,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      16.ph,
                      buildTextField("Başlık", controller.titleController),
                      16.ph,
                      buildTextField(
                        "Açıklama",
                        controller.descriptionController,
                        maxLines: 3,
                      ),
                      16.ph,
                      Row(
                        children: [
                          Expanded(child: buildCategorySelection(controller)),
                          8.pw,
                          Expanded(
                            child: buildTextField(
                              "Fiyat (₺)",
                              controller.priceController,
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      16.ph,
                      buildSelectionField(
                        "Ders Yeri",
                        controller.selectedLessonPlace,
                        [
                          'Öğrencinin Evi',
                          'Öğretmenin Evi',
                          'Öğrencinin veya Öğretmenin Evi',
                          "Uzaktan Eğitim",
                          "Ders Verme Alanı",
                        ],
                      ),
                      16.ph,
                      buildLocationSelector(controller),
                      16.ph,
                      buildSelectionField(
                        "Cinsiyet Tercihi",
                        controller.selectedGender,
                        ['Erkek', 'Kadın', 'Farketmez'],
                      ),
                      16.ph,
                      Container(
                        height: 50,
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Obx(
                              () => Text(
                                "Arama İzni ${controller.isPhoneOpen.value ? "Açık" : "Kapalı"}",
                                style: TextStyles.textFieldTitle,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => controller.togglePhoneOpen(
                                !controller.isPhoneOpen.value,
                              ),
                              child: Obx(
                                () => TurqAppToggle(
                                  isOn: controller.isPhoneOpen.value,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      16.ph,
                      // Doğrulama Belgeleri
                      Text("Doğrulama Belgeleri (Opsiyonel)",
                          style: TextStyles.textFieldTitle),
                      4.ph,
                      Text(
                        "Diploma veya sertifika yükleyerek doğrulanmış öğretmen rozeti alabilirsiniz.",
                        style: TextStyle(
                          fontFamily: "MontserratMedium",
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      8.ph,
                      Obx(() => Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...controller.verificationDocs.map((doc) => Chip(
                                    label: Text(
                                      doc.startsWith('http')
                                          ? "Belge ${controller.verificationDocs.indexOf(doc) + 1}"
                                          : doc.split('/').last,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    deleteIcon:
                                        const Icon(Icons.close, size: 16),
                                    onDeleted: () =>
                                        controller.verificationDocs.remove(doc),
                                  )),
                              GestureDetector(
                                onTap: () async {
                                  final pickedFiles =
                                      await AppImagePickerService.pickImages(
                                    context,
                                    maxAssets: 3,
                                  );
                                  for (var file in pickedFiles) {
                                    controller.addVerificationDoc(file.path);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey.shade300),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.upload_file,
                                          size: 18,
                                          color: Colors.grey.shade600),
                                      const SizedBox(width: 4),
                                      Text("Belge Ekle",
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey.shade600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )),
                      16.ph,
                      // Müsaitlik Takvimi
                      Text("Müsaitlik Takvimi",
                          style: TextStyles.textFieldTitle),
                      8.ph,
                      Obx(() {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children:
                                CreateTutoringController.weekDays.map((day) {
                              final selectedSlots =
                                  controller.availability[day] ?? [];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      day,
                                      style: const TextStyle(
                                        fontFamily: "MontserratBold",
                                        fontSize: 13,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: CreateTutoringController
                                          .timeSlots
                                          .map((slot) {
                                        final isSelected =
                                            selectedSlots.contains(slot);
                                        return GestureDetector(
                                          onTap: () => controller
                                              .toggleTimeSlot(day, slot),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? Colors.black
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isSelected
                                                    ? Colors.black
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                            child: Text(
                                              slot,
                                              style: TextStyle(
                                                fontFamily: "MontserratMedium",
                                                fontSize: 11,
                                                color: isSelected
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                      32.ph,
                      Obx(
                        () => GestureDetector(
                          onTap: controller.isLoading.value
                              ? null
                              : () {
                                  if (initialData != null) {
                                    controller.updateTutoring(
                                      initialData.docID,
                                    );
                                  } else {
                                    controller.saveTutoring();
                                  }
                                },
                          child: Container(
                            height: 50,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: controller.isLoading.value
                                  ? Colors.grey
                                  : Colors.black,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: controller.isLoading.value
                                ? CupertinoActivityIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    initialData != null ? "Güncelle" : "Paylaş",
                                    style: TextStyles.bold16White,
                                  ),
                          ),
                        ),
                      ),
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
}
