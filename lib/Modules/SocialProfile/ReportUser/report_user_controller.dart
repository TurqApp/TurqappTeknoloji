import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/report_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/report_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'report_user_controller_fields_part.dart';
part 'report_user_controller_runtime_part.dart';

abstract class _ReportUserControllerBase extends GetxController {
  _ReportUserControllerBase({
    required String userID,
    required String postID,
    required String commentID,
  }) : _state = _ReportUserControllerState(
          userID: userID,
          postID: postID,
          commentID: commentID,
        );

  final _ReportUserControllerState _state;

  @override
  void onInit() {
    super.onInit();
    _ReportUserControllerRuntimePart(this as ReportUserController).loadUser();
  }
}

class ReportUserController extends _ReportUserControllerBase {
  ReportUserController({
    required super.userID,
    required super.postID,
    required super.commentID,
  });
}

ReportUserController ensureReportUserController({
  required String userID,
  required String postID,
  required String commentID,
  String? tag,
  bool permanent = false,
}) {
  final existing = maybeFindReportUserController(tag: tag);
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

ReportUserController? maybeFindReportUserController({String? tag}) {
  final isRegistered = Get.isRegistered<ReportUserController>(tag: tag);
  if (!isRegistered) return null;
  return Get.find<ReportUserController>(tag: tag);
}
