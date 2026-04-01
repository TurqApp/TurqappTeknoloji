part of 'create_tutoring_controller.dart';

extension CreateTutoringControllerRuntimePart on CreateTutoringController {
  void _handleRuntimeInit() {
    loadSehirler();
    ever<String>(selectedBranch, (value) {
      branchController.text = value;
    });
  }

  void _handleRuntimeClose() {
    titleController.dispose();
    descriptionController.dispose();
    branchController.dispose();
    priceController.dispose();
    cityController.dispose();
    districtController.dispose();
  }

  void addImage(String imagePath) {
    images.add(imagePath);
  }

  void togglePhoneOpen(bool value) {
    isPhoneOpen.value = value;
  }
}
