part of 'report_user_controller.dart';

class _ReportUserControllerState {
  _ReportUserControllerState({
    required this.userID,
    required this.postID,
    required this.commentID,
  });

  final String userID;
  final String postID;
  final String commentID;
  final RxDouble step = 0.50.obs;
  final RxString nickname = "".obs;
  final RxString avatarUrl = "".obs;
  final RxString fullName = "".obs;
  final RxString selectedKey = "".obs;
  final RxString selectedTitle = "".obs;
  final RxString selectedDesc = "".obs;
  final RxBool blockedUser = false.obs;
  final RxBool isSubmitting = false.obs;
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final ReportRepository reportRepository = ReportRepository.ensure();
  final UserSubcollectionRepository userSubcollectionRepository =
      ensureUserSubcollectionRepository();
}

extension ReportUserControllerFieldsPart on ReportUserController {
  String get userID => _state.userID;
  String get postID => _state.postID;
  String get commentID => _state.commentID;
  RxDouble get step => _state.step;
  RxString get nickname => _state.nickname;
  RxString get avatarUrl => _state.avatarUrl;
  RxString get fullName => _state.fullName;
  RxString get selectedKey => _state.selectedKey;
  RxString get selectedTitle => _state.selectedTitle;
  RxString get selectedDesc => _state.selectedDesc;
  RxBool get blockedUser => _state.blockedUser;
  RxBool get isSubmitting => _state.isSubmitting;
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  ReportRepository get _reportRepository => _state.reportRepository;
  UserSubcollectionRepository get _userSubcollectionRepository =>
      _state.userSubcollectionRepository;
}
