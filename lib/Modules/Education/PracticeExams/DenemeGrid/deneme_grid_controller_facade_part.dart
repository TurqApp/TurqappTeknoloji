part of 'deneme_grid_controller.dart';

DenemeGridController ensureDenemeGridController({
  required String tag,
  bool permanent = false,
}) {
  final existing = maybeFindDenemeGridController(tag: tag);
  if (existing != null) return existing;
  return Get.put(DenemeGridController(), tag: tag, permanent: permanent);
}

DenemeGridController? maybeFindDenemeGridController({required String tag}) {
  final isRegistered = Get.isRegistered<DenemeGridController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<DenemeGridController>(tag: tag);
}

extension DenemeGridControllerFacadePart on DenemeGridController {
  void initData(SinavModel model) {
    if (_initializedDocId == model.docID) {
      return;
    }
    _initializedDocId = model.docID;
    examTime.value = model.timeStamp.toInt();
    toplamBasvuru.value = model.participantCount.toInt();
  }
}
