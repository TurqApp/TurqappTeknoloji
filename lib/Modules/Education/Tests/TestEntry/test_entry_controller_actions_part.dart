part of 'test_entry_controller.dart';

extension TestEntryControllerActionsPart on TestEntryController {
  void joinTest(BuildContext context) {
    if (model.value != null) {
      Get.to(
        () => SolveTest(testID: model.value!.docID, showSucces: showAlert),
      )?.then((_) {
        model.value = null;
        textController.text = '';
      });
    }
  }

  void showAlert() {
    showAlertDialog(
      Get.context!,
      'tests.completed_title'.tr,
      'tests.completed_body'.tr,
    );
  }
}
