import 'package:get/get.dart';
import 'package:turqappv2/Modules/SocialProfile/ReportUser/report_user.dart';

class ReportUserNavigationService {
  const ReportUserNavigationService();

  Future<void> openReportUser({
    required String userId,
    required String postId,
    String commentId = '',
  }) async {
    await Get.to(
      () => ReportUser(
        userID: userId,
        postID: postId,
        commentID: commentId,
      ),
    );
  }
}
