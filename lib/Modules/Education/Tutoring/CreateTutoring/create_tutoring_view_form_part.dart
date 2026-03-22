part of 'create_tutoring_view.dart';

extension CreateTutoringViewFormPart on _CreateTutoringViewState {
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
    final imagePath =
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
