part of 'job_selector_controller.dart';

class _JobSelectorControllerState {
  final RxString job = ''.obs;
  final RxList<String> filteredJobs = <String>[].obs;
  late List<String> initialJobs;
}

extension JobSelectorControllerFieldsPart on JobSelectorController {
  RxString get job => _state.job;
  RxList<String> get filteredJobs => _state.filteredJobs;
  CurrentUserService get _userService => CurrentUserService.instance;
  List<String> get _initialJobs => _state.initialJobs;
  set _initialJobs(List<String> value) => _state.initialJobs = value;
}
