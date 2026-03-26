part of 'tutoring_detail_controller.dart';

TutoringDetailController ensureTutoringDetailController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindTutoringDetailController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    TutoringDetailController(),
    tag: tag,
    permanent: permanent,
  );
}

TutoringDetailController? maybeFindTutoringDetailController({String? tag}) {
  final isRegistered = Get.isRegistered<TutoringDetailController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<TutoringDetailController>(tag: tag);
}

extension TutoringDetailControllerFacadePart on TutoringDetailController {
  Future<void> fetchUserData(String userID) =>
      _TutoringDetailControllerRuntimeX(this).fetchUserData(userID);

  Future<void> fetchTutoringDetail(String docID) =>
      _TutoringDetailControllerRuntimeX(this).fetchTutoringDetail(docID);

  Future<void> checkBasvuru(String docID) =>
      _TutoringDetailControllerRuntimeX(this).checkBasvuru(docID);

  Future<void> toggleBasvuru(String docId) =>
      _TutoringDetailControllerActionsX(this).toggleBasvuru(docId);

  Future<void> unpublishTutoring() =>
      _TutoringDetailControllerActionsX(this).unpublishTutoring();

  Future<void> getSimilar(String brans, String currentDocID) =>
      _TutoringDetailControllerRuntimeX(this).getSimilar(brans, currentDocID);
}
