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
import 'package:turqappv2/Core/Widgets/app_header_action_button.dart';
import 'package:turqappv2/Core/Widgets/pasaj_selection_chip.dart';
import 'package:turqappv2/Models/Education/tutoring_model.dart';
import 'package:turqappv2/Modules/Education/Tutoring/tutoring_category.dart';

import 'create_tutoring_controller.dart';

class CreateTutoringView extends StatefulWidget {
  const CreateTutoringView({super.key});

  @override
  State<CreateTutoringView> createState() => _CreateTutoringViewState();
}

class _CreateTutoringViewState extends State<CreateTutoringView> {
  late final String _tag;
  late final CreateTutoringController controller;
  late final bool _ownsController;
  late final TutoringModel? _initialData;

  @override
  void initState() {
    super.initState();
    _tag = 'create_tutoring_${identityHashCode(this)}';
    _initialData = Get.arguments as TutoringModel?;
    if (Get.isRegistered<CreateTutoringController>(tag: _tag)) {
      controller = Get.find<CreateTutoringController>(tag: _tag);
      _ownsController = false;
    } else {
      controller = Get.put(CreateTutoringController(), tag: _tag);
      _ownsController = true;
    }
    _hydrateInitialData();
  }

  void _hydrateInitialData() {
    final initialData = _initialData;
    if (initialData == null) return;
    if (controller.titleController.text.isNotEmpty ||
        controller.descriptionController.text.isNotEmpty ||
        controller.branchController.text.isNotEmpty ||
        controller.images.isNotEmpty) {
      return;
    }

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

  @override
  void dispose() {
    if (_ownsController &&
        Get.isRegistered<CreateTutoringController>(tag: _tag) &&
        identical(Get.find<CreateTutoringController>(tag: _tag), controller)) {
      Get.delete<CreateTutoringController>(tag: _tag);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 52,
        titleSpacing: 8,
        leading: const AppBackButton(),
        title: AppPageTitle(
          _initialData == null
              ? 'tutoring.create_listing'.tr
              : 'common.update'.tr,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(15, 8, 15, 24),
            children: [
              _buildImagePicker(context, controller, _initialData),
              const SizedBox(height: 18),
              _sectionTitle('scholarship.basic_info'.tr),
              const SizedBox(height: 8),
              TextField(
                controller: controller.titleController,
                inputFormatters: [LengthLimitingTextInputFormatter(100)],
                decoration: _inputDecoration('scholarship.title_label'.tr),
              ),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.selectedBranch.value.isEmpty
                    ? 'tutoring.branch'.tr
                    : tutoringBranchLabel(controller.selectedBranch.value),
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
                decoration: _inputDecoration('common.price'.tr),
              ),
              const SizedBox(height: 18),
              _sectionTitle('common.location'.tr),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _selectionField(
                      label: controller.city.value.isEmpty
                          ? 'common.city'.tr
                          : controller.city.value,
                      onTap: controller.showIlSec,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _selectionField(
                      label: controller.town.isEmpty
                          ? 'common.district'.tr
                          : controller.town,
                      onTap: controller.city.value.isEmpty
                          ? null
                          : controller.showIlcelerSec,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _sectionTitle('common.description'.tr),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.selectedLessonPlace.value.isEmpty
                    ? 'tutoring.lesson_place_title'.tr
                    : _lessonPlaceLabel(controller.selectedLessonPlace.value),
                onTap: () => _showListSelector(
                  context: context,
                  title: 'tutoring.lesson_place_title'.tr,
                  items: const [
                    'tutoring.lesson_place.student_home',
                    'tutoring.lesson_place.teacher_home',
                    'tutoring.lesson_place.either_home',
                    'tutoring.lesson_place.remote',
                    'tutoring.lesson_place.lesson_area',
                  ],
                  selected: controller.selectedLessonPlace.value,
                  onSelect: (value) =>
                      controller.selectedLessonPlace.value = value,
                  itemLabelBuilder: (value) => value.tr,
                ),
              ),
              const SizedBox(height: 8),
              _selectionField(
                label: controller.selectedGender.value.isEmpty
                    ? 'tutoring.gender_title'.tr
                    : _genderLabel(controller.selectedGender.value),
                onTap: () => _showListSelector(
                  context: context,
                  title: 'tutoring.gender_title'.tr,
                  items: const [
                    'tutoring.gender.male',
                    'tutoring.gender.female',
                    'tutoring.gender.any',
                  ],
                  selected: controller.selectedGender.value,
                  onSelect: (value) => controller.selectedGender.value = value,
                  itemLabelBuilder: (value) => value.tr,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: controller.descriptionController,
                minLines: 4,
                maxLines: 8,
                inputFormatters: [LengthLimitingTextInputFormatter(2000)],
                decoration: _inputDecoration('common.description'.tr),
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
                    Expanded(
                      child: Text(
                        'search_permission.title'.tr,
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
              _sectionTitle('tutoring.detail_availability'.tr),
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
                          if (_initialData != null) {
                            controller.updateTutoring(_initialData.docID);
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
                          _initialData == null
                              ? 'common.publish'.tr
                              : 'common.update'.tr,
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
      AppSnackbar('common.error'.tr, 'tutoring.create.nsfw_check_failed'.tr);
      return;
    }
    if (result.isNSFW) {
      AppSnackbar('common.error'.tr, 'tutoring.create.nsfw_detected'.tr);
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
    final String? imagePath =
        controller.images.isNotEmpty ? controller.images.first : null;

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
                label: 'profile_photo.gallery'.tr,
                primary: true,
                onTap: () => _pickImage(
                  context,
                  controller,
                  source: ImageSource.gallery,
                ),
              ),
              const SizedBox(height: 8),
              _imageActionButton(
                label: 'profile_photo.camera'.tr,
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
    String Function(dynamic)? itemLabelBuilder,
  }) {
    AppBottomSheet.show(
      context: context,
      title: title,
      items: items,
      selectedItem: selected,
      itemLabelBuilder: itemLabelBuilder,
      onSelect: (value) => onSelect(value.toString()),
    );
  }

  void _showBranchSelector(
    BuildContext context,
    CreateTutoringController controller,
  ) {
    AppBottomSheet.show(
      context: context,
      title: 'tutoring.branch'.tr,
      items: controller.branchIconMap.keys.toList(),
      selectedItem: controller.selectedBranch.value,
      itemLabelBuilder: (value) => tutoringBranchLabel(value.toString()),
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
                      return PasajSelectionChip(
                        label: slot,
                        selected: isSelected,
                        onTap: () => controller.toggleTimeSlot(day, slot),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        fontSize: 11,
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

  String _lessonPlaceLabel(String value) {
    switch (value) {
      case 'tutoring.lesson_place.student_home':
      case 'Öğrencinin Evi':
        return 'tutoring.lesson_place.student_home'.tr;
      case 'tutoring.lesson_place.teacher_home':
      case 'Öğretmenin Evi':
        return 'tutoring.lesson_place.teacher_home'.tr;
      case 'tutoring.lesson_place.either_home':
      case 'Öğrencinin veya Öğretmenin Evi':
        return 'tutoring.lesson_place.either_home'.tr;
      case 'tutoring.lesson_place.remote':
      case 'Uzaktan Eğitim':
        return 'tutoring.lesson_place.remote'.tr;
      case 'tutoring.lesson_place.lesson_area':
      case 'Ders Verme Alanı':
        return 'tutoring.lesson_place.lesson_area'.tr;
      default:
        return value;
    }
  }

  String _genderLabel(String value) {
    switch (value) {
      case 'tutoring.gender.male':
      case 'Erkek':
        return 'tutoring.gender.male'.tr;
      case 'tutoring.gender.female':
      case 'Kadın':
        return 'tutoring.gender.female'.tr;
      case 'tutoring.gender.any':
      case 'Farketmez':
        return 'tutoring.gender.any'.tr;
      default:
        return value;
    }
  }
}
