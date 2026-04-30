part of 'complaint.dart';

ComplaintController ensureComplaintController({
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindComplaintController(tag: tag);
  if (existing != null) return existing;
  return Get.put(
    ComplaintController(),
    tag: tag,
    permanent: permanent,
  );
}

ComplaintController? maybeFindComplaintController({String? tag}) {
  final isRegistered = Get.isRegistered<ComplaintController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ComplaintController>(tag: tag);
}

extension ComplaintControllerFacadePart on ComplaintController {
  Future<void> submitSikayet(
    String postID,
    String sikayetTitle,
    String sikayetDesc,
  ) async {
    final sikayet = Complaint(
      postID: postID,
      sikayetDesc: sikayetDesc,
      sikayetTitle: sikayetTitle,
      timeStamp: DateTime.now().millisecondsSinceEpoch,
      userID: userID,
      yorumID: '',
    );

    try {
      await ensureReportRepository().submitTrainingComplaint(sikayet.toJson());
      AppSnackbar('common.success'.tr, 'training.complaint_thanks'.tr);
    } catch (_) {
      AppSnackbar('common.error'.tr, 'training.complaint_submit_failed'.tr);
    }
  }
}
