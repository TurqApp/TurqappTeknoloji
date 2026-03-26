part of 'report_user_controller.dart';

class ReportUserController extends GetxController {
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
