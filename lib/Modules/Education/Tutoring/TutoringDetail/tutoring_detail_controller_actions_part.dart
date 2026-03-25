part of 'tutoring_detail_controller.dart';

class _TutoringDetailControllerActionsX {
  final TutoringDetailController controller;

  const _TutoringDetailControllerActionsX(this.controller);

  Future<void> toggleBasvuru(String docId) async {
    final uid = controller._uid;
    if (uid.isEmpty) {
      AppSnackbar('common.error'.tr, 'tutoring.apply_login_required'.tr);
      return;
    }

    try {
      final t = controller.tutoring.value;
      final ownerData = controller.users[t.userID];
      final tutorName =
          (ownerData?['displayName'] ?? ownerData?['nickname'] ?? '')
              .toString()
              .trim();
      final tutorImage = (ownerData?['avatarUrl'] ?? '').toString();
      final currentUserSummary = await controller._userSummaryResolver.resolve(
        uid,
        preferCache: true,
      );
      final applicantName = currentUserSummary?.displayName.trim() ?? '';
      final applicantLabel =
          applicantName.isNotEmpty ? applicantName : 'common.some_user'.tr;
      final applicantImage = currentUserSummary?.avatarUrl.trim() ?? '';

      final isApplied = await controller._tutoringRepository.toggleApplication(
        tutoringId: docId,
        ownerUid: controller.tutoring.value.userID,
        userId: uid,
        tutoringTitle: t.baslik,
        tutorName: tutorName,
        tutorImage: tutorImage,
        applicantLabel: applicantLabel,
        applicantImage: applicantImage,
      );
      controller.basvuruldu.value = isApplied;
      if (isApplied) {
        AppSnackbar('common.success'.tr, 'tutoring.application_sent'.tr);
      }
    } catch (_) {
      AppSnackbar('common.error'.tr, 'tutoring.application_failed'.tr);
    }
  }

  Future<void> unpublishTutoring() async {
    final docId = controller.tutoring.value.docID;
    try {
      await controller._tutoringRepository.unpublish(docId);
    } catch (_) {}
  }
}
