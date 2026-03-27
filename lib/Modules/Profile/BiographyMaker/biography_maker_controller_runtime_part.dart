part of 'biography_maker_controller.dart';

void _handleBiographyMakerInit(BiographyMakerController controller) {
  final initialBio = controller.userService.currentUser?.bio ?? '';
  controller.bioController.text = initialBio;
  controller.currentLength.value = initialBio.length;
  controller.bioController.addListener(() {
    controller.currentLength.value = controller.bioController.text.length;
  });
}

void _handleBiographyMakerClose(BiographyMakerController controller) {
  controller.bioController.dispose();
}

Future<void> _saveBiographyData(BiographyMakerController controller) async {
  if (controller.isSaving.value) return;
  controller.isSaving.value = true;
  try {
    await controller.userService.updateFields({
      'bio': controller.bioController.text.trim(),
    });
    Get.back();
  } finally {
    controller.isSaving.value = false;
  }
}

extension BiographyMakerControllerFacadePart on BiographyMakerController {
  Future<void> setData() => _saveBiographyData(this);
}
