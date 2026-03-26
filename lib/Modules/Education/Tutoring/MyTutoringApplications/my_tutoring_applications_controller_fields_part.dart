part of 'my_tutoring_applications_controller.dart';

class _MyTutoringApplicationsControllerState {
  final UserSubcollectionRepository subcollectionRepository =
      ensureUserSubcollectionRepository();
  final TutoringRepository tutoringRepository = ensureTutoringRepository();
  final RxList<TutoringApplicationModel> applications =
      <TutoringApplicationModel>[].obs;
  final RxBool isLoading = false.obs;
}

extension MyTutoringApplicationsControllerFieldsPart
    on MyTutoringApplicationsController {
  UserSubcollectionRepository get _subcollectionRepository =>
      _state.subcollectionRepository;
  TutoringRepository get _tutoringRepository => _state.tutoringRepository;
  RxList<TutoringApplicationModel> get applications => _state.applications;
  RxBool get isLoading => _state.isLoading;
}
