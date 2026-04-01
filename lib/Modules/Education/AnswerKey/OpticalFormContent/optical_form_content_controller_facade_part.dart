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

OpticalFormContentController ensureOpticalFormContentController(
  OpticalFormModel model, {
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindOpticalFormContentController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    OpticalFormContentController(model),
    tag: tag,
    permanent: permanent,
  );
}

OpticalFormContentController? maybeFindOpticalFormContentController({
  String? tag,
}) {
  final isRegistered = Get.isRegistered<OpticalFormContentController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<OpticalFormContentController>(tag: tag);
}

extension OpticalFormContentControllerDataPart on OpticalFormContentController {
  Future<void> fetchTotal() async => total
    ..value = 0
    ..value = await _opticalFormRepository.fetchAnswerCount(model.docID);

  Future<void> deleteOpticalForm() async {
    try {
      await _opticalFormRepository.deleteForm(model.docID);
    } catch (_) {}
  }
}
