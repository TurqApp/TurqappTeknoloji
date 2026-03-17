import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/BottomSheets/app_bottom_sheet.dart';
import 'package:turqappv2/Core/Buttons/turq_app_toggle.dart';
import 'package:turqappv2/Core/Services/app_image_picker_service.dart';
import 'package:turqappv2/Core/Services/optimized_nsfw_service.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';

import 'create_tutoring_controller.dart';

class CreateTutoringView extends StatelessWidget {
  const CreateTutoringView({super.key});

  @override
  Widget build(BuildContext context) {
    final CreateTutoringController controller = Get.put(
      CreateTutoringController(),
    );
    final TutoringModel? initialData = Get.arguments as TutoringModel?;

    if (initialData != null &&
        controller.titleController.text.isEmpty &&
        controller.descriptionController.text.isEmpty &&
        controller.branchController.text.isEmpty &&
        controller.images.isEmpty) {
      controller.titleController.text = initialData.baslik;
      controller.descriptionController.text = initialData.aciklama;
      controller.branchController.text = initialData.brans;
      controller.priceController.text = initialData.fiyat.toString();
      controller.cityController.text = initialData.sehir;
      controller.districtController.text = initialData.ilce;
      controller.selectedLessonPlace.value =
          initialData.dersYeri.isNotEmpty ? initialData.dersYeri.first : '';
      controller.selectedGender.value = initialData.cinsiyet;
      controller.city.value = initialData.sehir;
      controller.town = initialData.ilce;
      controller.isPhoneOpen.value = initialData.telefon;
      controller.selectedBranch.value = initialData.brans;
      if (initialData.imgs != null && initialData.imgs!.isNotEmpty) {
        controller.images.assignAll(initialData.imgs!);
      }
      if (initialData.availability != null) {
        controller.availability.assignAll(initialData.availability!);
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(CupertinoIcons.arrow_left, color: Colors.black),
        ),
        title: Text(
          initialData == null ? 'İlan Ekle' : 'İlan Düzenle',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
            children: [
              _buildImagePicker(context, controller, initialData),
              const SizedBox(height: 18),
              _sectionTitle('Temel Bilgiler'),
              const SizedBox(height: 8),
              TextField(
                controller: controller.titleController,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                decoration: _inputDecoration('İlan Başlığı'),
              ),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.selectedBranch.value.isEmpty
                    ? 'Branş'
                    : controller.selectedBranch.value,
                onTap: () => _showBranchSelector(context, controller),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.priceController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                decoration: _inputDecoration('Ücret'),
              ),
              const SizedBox(height: 18),
              _sectionTitle('Konum'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _selectionField(
                      label: controller.city.value.isEmpty
                          ? 'Şehir'
                          : controller.city.value,
                      onTap: controller.showIlSec,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _selectionField(
                      label: controller.town.isEmpty
                          ? 'İlçe'
                          : controller.town,
                      onTap: controller.city.value.isEmpty
                          ? null
                          : controller.showIlcelerSec,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _sectionTitle('Ders Tanımı'),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.selectedLessonPlace.value.isEmpty
                    ? 'Ders Yeri'
                    : controller.selectedLessonPlace.value,
                onTap: () => _showListSelector(
                  context: context,
                  title: 'Ders Yeri',
                  items: const [
                    'Öğrencinin Evi',
                    'Öğretmenin Evi',
                    'Öğrencinin veya Öğretmenin Evi',
                    'Uzaktan Eğitim',
                    'Ders Verme Alanı',
                  ],
                  selected: controller.selectedLessonPlace.value,
                  onSelect: (value) => controller.selectedLessonPlace.value = value,
                ),
              ),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.selectedGender.value.isEmpty
                    ? 'Cinsiyet Tercihi'
                    : controller.selectedGender.value,
                onTap: () => _showListSelector(
                  context: context,
                  title: 'Cinsiyet Tercihi',
                  items: const ['Erkek', 'Kadın', 'Farketmez'],
                  selected: controller.selectedGender.value,
                  onSelect: (value) => controller.selectedGender.value = value,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.descriptionController,
                minLines: 4,
                maxLines: 8,
                inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                decoration: _inputDecoration('Açıklama'),
              ),
              const SizedBox(height: 8),
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x22000000)),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Arama İzni',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontFamily: 'MontserratMedium',
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => controller.togglePhoneOpen(
                        !controller.isPhoneOpen.value,
                      ),
                      child: TurqAppToggle(isOn: controller.isPhoneOpen.value),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _sectionTitle('Müsaitlik Takvimi'),
              const SizedBox(height: 8),
              _buildAvailabilityCard(controller),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.isLoading.value
                      ? null
                      : () {
                          if (initialData != null) {
                            controller.updateTutoring(initialData.docID);
                          } else {
                            controller.saveTutoring();
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: controller.isLoading.value
                      ? const CupertinoActivityIndicator(color: Colors.white)
                      : Text(
                          initialData == null ? 'Yayınla' : 'Güncelle',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontFamily: 'MontserratBold',
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    CreateTutoringController controller, {
    required ImageSource source,
  }) async {
    File? file;
    if (source == ImageSource.gallery) {
      file = await AppImagePickerService.pickSingleImage(context);
    } else {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );
      if (picked != null) file = File(picked.path);
    }
    if (file == null) return;

    final result = await OptimizedNSFWService.checkImage(file);
    if (result.errorMessage != null) {
      AppSnackbar('Hata', 'Görsel kontrolü başarısız oldu.');
      return;
    }
    if (result.isNSFW) {
      AppSnackbar('Hata', 'Uygunsuz görsel tespit edildi.');
      return;
    }

    controller.images
      ..clear()
      ..add(file.path);
  }

  Widget _buildImagePicker(
    BuildContext context,
    CreateTutoringController controller,
    TutoringModel? initialData,
  ) {
    final String? imagePath = controller.images.isNotEmpty
        ? controller.images.first
        : null;

    Widget preview;
    if (imagePath != null) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 112,
          height: 112,
          child: imagePath.startsWith('http')
              ? CachedNetworkImage(imageUrl: imagePath, fit: BoxFit.cover)
              : Image.file(File(imagePath), fit: BoxFit.cover),
        ),
      );
    } else if (initialData?.imgs?.isNotEmpty ?? false) {
      preview = ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 112,
          height: 112,
          child: CachedNetworkImage(
            imageUrl: initialData!.imgs!.first,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      preview = Container(
        width: 112,
        height: 112,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: const Icon(
          CupertinoIcons.person_2_fill,
          color: Colors.black38,
          size: 38,
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        preview,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              _imageActionButton(
                label: 'Galeriden Seç',
                primary: true,
                onTap: () => _pickImage(
                  context,
                  controller,
                  source: ImageSource.gallery,
                ),
              ),
              const SizedBox(height: 8),
              _imageActionButton(
                label: 'Kameradan Çek',
                onTap: () => _pickImage(
                  context,
                  controller,
                  source: ImageSource.camera,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _imageActionButton({
    required String label,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary ? Colors.black : const Color(0x22000000),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primary ? Colors.white : Colors.black,
            fontSize: 14,
            fontFamily: 'MontserratBold',
          ),
        ),
      ),
    );
  }

  Widget _selectionField({
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x22000000)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: onTap == null ? Colors.black38 : Colors.black87,
                  fontSize: 15,
                  fontFamily: 'MontserratMedium',
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(CupertinoIcons.chevron_down, size: 20),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0x22000000)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.black12),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black,
        fontSize: 18,
        fontFamily: 'MontserratBold',
      ),
    );
  }

  void _showListSelector({
    required BuildContext context,
    required String title,
    required List<String> items,
    required String selected,
    required ValueChanged<String> onSelect,
  }) {
    AppBottomSheet.show(
      context: context,
      title: title,
      items: items,
      selectedItem: selected,
      onSelect: (value) => onSelect(value.toString()),
    );
  }

  void _showBranchSelector(
    BuildContext context,
    CreateTutoringController controller,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'Branş',
      items: controller.branchIconMap.keys.toList(),
      selectedItem: controller.selectedBranch.value,
      onSelect: (value) {
        controller.selectedBranch.value = value;
        controller.branchController.text = value;
      },
    );
  }

  Widget _buildAvailabilityCard(CreateTutoringController controller) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF6F7FB),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: CreateTutoringController.weekDays.map((day) {
            final selectedSlots = controller.availability[day] ?? <String>[];
            return Padding(
              padding: EdgeInsets.only(
                bottom: day == CreateTutoringController.weekDays.last ? 0 : 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13,
                      fontFamily: 'MontserratBold',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: CreateTutoringController.timeSlots.map((slot) {
                      final isSelected = selectedSlots.contains(slot);
                      return GestureDetector(
                        onTap: () => controller.toggleTimeSlot(day, slot),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.black
                                  : const Color(0x22000000),
                            ),
                          ),
                          child: Text(
                            slot,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 11,
                              fontFamily: 'MontserratMedium',
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
      ),
    );
  }
}
