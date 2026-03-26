part of 'complaint.dart';

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
      await FirebaseFirestore.instance
          .collection('reports')
          .add(sikayet.toJson());
      AppSnackbar('common.success'.tr, 'training.complaint_thanks'.tr);
    } catch (_) {
      AppSnackbar('common.error'.tr, 'training.complaint_submit_failed'.tr);
    }
  }
}
