import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/report_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/report_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'report_user_controller_runtime_part.dart';

class ReportUserController extends GetxController {
  static ReportUserController ensure({
    required String userID,
    required String postID,
    required String commentID,
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ReportUserController(
        userID: userID,
        postID: postID,
        commentID: commentID,
      ),
      tag: tag,
      permanent: permanent,
    );
  }

  static ReportUserController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<ReportUserController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ReportUserController>(tag: tag);
  }

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
    _ReportUserControllerRuntimePart(this).loadUser();
  }

  Future<void> report() => _ReportUserControllerRuntimePart(this).report();

  Future<void> block() => _ReportUserControllerRuntimePart(this).block();
}
