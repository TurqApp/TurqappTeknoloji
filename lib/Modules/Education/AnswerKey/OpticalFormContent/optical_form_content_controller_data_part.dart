part of 'optical_form_content_controller.dart';

extension OpticalFormContentControllerDataPart on OpticalFormContentController {
  Future<void> fetchTotal() async {
    total.value = 0;
    total.value = await _opticalFormRepository.fetchAnswerCount(model.docID);
  }

  Future<void> deleteOpticalForm() async {
    try {
      await _opticalFormRepository.deleteForm(model.docID);
    } catch (_) {}
  }
}
