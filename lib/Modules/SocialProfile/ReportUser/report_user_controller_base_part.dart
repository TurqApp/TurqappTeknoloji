part of 'report_user_controller.dart';

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
