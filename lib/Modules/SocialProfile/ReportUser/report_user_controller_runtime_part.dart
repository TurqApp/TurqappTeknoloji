part of 'report_user_controller.dart';

class _ReportUserControllerRuntimePart {
  final ReportUserController controller;

  const _ReportUserControllerRuntimePart(this.controller);

  Future<void> loadUser() async {
    final data = await controller._userSummaryResolver.resolve(
      controller.userID,
      preferCache: true,
    );
    if (data == null) return;
    controller.nickname.value = data.nickname;
    controller.avatarUrl.value = data.avatarUrl;
    controller.fullName.value = data.displayName;
  }

  Future<void> report() async {
    if (controller.isSubmitting.value) return;
    if (controller.selectedKey.value.trim().isEmpty ||
        controller.selectedTitle.value.trim().isEmpty ||
        controller.selectedDesc.value.trim().isEmpty) {
      AppSnackbar(
        'report.select_reason_title'.tr,
        'report.select_reason_body'.tr,
      );
      return;
    }

    controller.isSubmitting.value = true;
    try {
      await controller._reportRepository.submitReport(
        targetUserId: controller.userID,
        postId: controller.postID,
        commentId: controller.commentID,
        selection: ReportModel(
          key: controller.selectedKey.value,
          title: controller.selectedTitle.value,
          description: controller.selectedDesc.value,
        ),
      );

      Get.back();

      AppSnackbar(
        'report.submitted_title'.tr,
        'report.submitted_body'.trParams({
          'nickname': controller.nickname.value,
        }),
      );
    } finally {
      controller.isSubmitting.value = false;
    }
  }

  Future<void> block() async {
    final currentUserID = CurrentUserService.instance.effectiveUserId;
    final blockedEntries =
        await controller._userSubcollectionRepository.getEntries(
      controller.userID,
      subcollection: "blockedUsers",
      preferCache: true,
    );
    final exists = blockedEntries.any((entry) => entry.id == currentUserID);
    if (exists) {
      await controller._userSubcollectionRepository.deleteEntry(
        controller.userID,
        subcollection: "blockedUsers",
        docId: currentUserID,
      );
      controller.blockedUser.value = false;
      return;
    }

    await controller._userSubcollectionRepository.upsertEntry(
      controller.userID,
      subcollection: "blockedUsers",
      docId: currentUserID,
      data: {
        "userID": currentUserID,
        "updatedDate": DateTime.now().millisecondsSinceEpoch,
      },
    );
    controller.blockedUser.value = true;
  }
}
