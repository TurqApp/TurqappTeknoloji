part of 'applications_controller_library.dart';

class _ApplicationsControllerState {
  final userSummaryResolver = UserSummaryResolver.ensure();
  final scholarshipRepository = ensureScholarshipRepository();
  final isLoading = true.obs;
  final applications = <Map<String, dynamic>>[].obs;
}

extension ApplicationsControllerFieldsPart on ApplicationsController {
  static final Expando<_ApplicationsControllerState> _stateExpando =
      Expando<_ApplicationsControllerState>('applications_controller_state');

  _ApplicationsControllerState get _state =>
      _stateExpando[this] ??= _ApplicationsControllerState();

  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  ScholarshipRepository get _scholarshipRepository =>
      _state.scholarshipRepository;
  RxBool get isLoading => _state.isLoading;
  RxList<Map<String, dynamic>> get applications => _state.applications;
}
