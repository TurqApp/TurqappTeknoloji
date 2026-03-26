part of 'optical_form_content_controller.dart';

class OpticalFormContentController extends GetxController {
  final OpticalFormModel model;
  final total = 0.obs;
  final OpticalFormRepository _opticalFormRepository =
      ensureOpticalFormRepository();

  OpticalFormContentController(this.model) {
    fetchTotal();
  }
}
