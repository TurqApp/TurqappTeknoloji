part of 'complaint.dart';

class ComplaintController extends GetxController {
  static ComplaintController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ComplaintController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static ComplaintController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ComplaintController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ComplaintController>(tag: tag);
  }

  final RxString selectedSikayet = ''.obs;
  final String userID = CurrentUserService.instance.effectiveUserId;

  void submitSikayet(
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
      await FirebaseFirestore.instance
          .collection('reports')
          .add(sikayet.toJson());
      AppSnackbar('common.success'.tr, 'training.complaint_thanks'.tr);
    } catch (_) {
      AppSnackbar('common.error'.tr, 'training.complaint_submit_failed'.tr);
    }
  }
}
