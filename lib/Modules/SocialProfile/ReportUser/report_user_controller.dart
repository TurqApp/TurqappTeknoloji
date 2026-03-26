import 'package:get/get.dart';
import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/report_repository.dart';
import 'package:turqappv2/Core/Repositories/user_subcollection_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Models/report_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'report_user_controller_fields_part.dart';
part 'report_user_controller_facade_part.dart';
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

  final _ReportUserControllerState _state;

  ReportUserController({
    required String userID,
    required String postID,
    required String commentID,
  }) : _state = _ReportUserControllerState(
          userID: userID,
          postID: postID,
          commentID: commentID,
        );

  @override
  void onInit() {
    super.onInit();
    _ReportUserControllerRuntimePart(this).loadUser();
  }
}
