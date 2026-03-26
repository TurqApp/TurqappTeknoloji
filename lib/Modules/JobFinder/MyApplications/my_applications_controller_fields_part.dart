part of 'my_applications_controller.dart';

class _MyApplicationsControllerState {
  final subcollectionRepository = ensureUserSubcollectionRepository();
  final jobRepository = ensureJobRepository();
  final applications = <JobApplicationModel>[].obs;
  final isLoading = false.obs;
}

extension MyApplicationsControllerFieldsPart on MyApplicationsController {
  static final Expando<_MyApplicationsControllerState> _stateExpando =
      Expando<_MyApplicationsControllerState>('my_applications_state');

  _MyApplicationsControllerState get _state =>
      _stateExpando[this] ??= _MyApplicationsControllerState();

  UserSubcollectionRepository get _subcollectionRepository =>
      _state.subcollectionRepository;
  JobRepository get _jobRepository => _state.jobRepository;
  RxList<JobApplicationModel> get applications => _state.applications;
  RxBool get isLoading => _state.isLoading;
}
