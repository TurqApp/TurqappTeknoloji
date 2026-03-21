import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/report_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/report_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

class ReportUserController extends GetxController {
  String userID;
  String postID;
  String commentID;
  ReportUserController({
    required this.userID,
    required this.postID,
    required this.commentID,
  });

  var step = 0.50.obs;
  var nickname = "".obs;
  var avatarUrl = "".obs;
  var fullName = "".obs;
  var selectedKey = "".obs;
  var selectedTitle = "".obs;
  var selectedDesc = "".obs;
  var blockedUser = false.obs;
  var isSubmitting = false.obs;
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final ReportRepository _reportRepository = ReportRepository.ensure();
  final UserSubcollectionRepository _userSubcollectionRepository =
      UserSubcollectionRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final data = await _userSummaryResolver.resolve(
      userID,
      preferCache: true,
    );
    if (data == null) return;
    nickname.value = data.nickname;
    avatarUrl.value = data.avatarUrl;
    fullName.value = data.displayName;
  }

  Future<void> report() async {
    if (isSubmitting.value) return;
    if (selectedKey.value.trim().isEmpty ||
        selectedTitle.value.trim().isEmpty ||
        selectedDesc.value.trim().isEmpty) {
      AppSnackbar(
        'report.select_reason_title'.tr,
        'report.select_reason_body'.tr,
      );
      return;
    }

    isSubmitting.value = true;
    try {
      await _reportRepository.submitReport(
        targetUserId: userID,
        postId: postID,
        commentId: commentID,
        selection: ReportModel(
          key: selectedKey.value,
          title: selectedTitle.value,
          description: selectedDesc.value,
        ),
      );

      Get.back();

      AppSnackbar(
        'report.submitted_title'.tr,
        'report.submitted_body'.trParams({
          'nickname': nickname.value,
        }),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> block() async {
    final currentUserID = CurrentUserService.instance.userId;
    final blockedEntries = await _userSubcollectionRepository.getEntries(
      userID,
      subcollection: "blockedUsers",
      preferCache: true,
    );
    final exists = blockedEntries.any((entry) => entry.id == currentUserID);
    if (exists) {
      await _userSubcollectionRepository.deleteEntry(
        userID,
        subcollection: "blockedUsers",
        docId: currentUserID,
      );
      blockedUser.value = false;
      return;
    }

    await _userSubcollectionRepository.upsertEntry(
      userID,
      subcollection: "blockedUsers",
      docId: currentUserID,
      data: {
        "userID": currentUserID,
        "updatedDate": DateTime.now().millisecondsSinceEpoch,
      },
    );
    blockedUser.value = true;
  }
}
