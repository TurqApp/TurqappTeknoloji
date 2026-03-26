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

part 'create_tutoring_view_form_part.dart';
part 'create_tutoring_view_ui_part.dart';

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
    _ownsController = maybeFindCreateTutoringController(tag: _tag) == null;
    controller = ensureCreateTutoringController(tag: _tag);
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
        identical(
          maybeFindCreateTutoringController(tag: _tag),
          controller,
        )) {
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
}
