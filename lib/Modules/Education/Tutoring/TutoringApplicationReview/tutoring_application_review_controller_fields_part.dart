part of 'tutoring_application_review_controller.dart';

class _TutoringApplicationReviewControllerState {
  _TutoringApplicationReviewControllerState({required this.tutoringDocID});

  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final TutoringRepository tutoringRepository = ensureTutoringRepository();
  final String tutoringDocID;
  final applicants = <TutoringApplicationModel>[].obs;
  final isLoading = false.obs;
}

extension TutoringApplicationReviewControllerFieldsPart
    on TutoringApplicationReviewController {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  TutoringRepository get _tutoringRepository => _state.tutoringRepository;
  String get tutoringDocID => _state.tutoringDocID;
  RxList<TutoringApplicationModel> get applicants => _state.applicants;
  RxBool get isLoading => _state.isLoading;
}
