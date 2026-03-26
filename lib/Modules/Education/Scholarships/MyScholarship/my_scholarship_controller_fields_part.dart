part of 'my_scholarship_controller.dart';

class _MyScholarshipControllerState {
  final UserSummaryResolver userSummaryResolver = UserSummaryResolver.ensure();
  final ScholarshipRepository scholarshipRepository =
      ensureScholarshipRepository();
  final RxBool isLoading = true.obs;
  final RxList<Map<String, dynamic>> myScholarships =
      <Map<String, dynamic>>[].obs;
}

extension MyScholarshipControllerFieldsPart on MyScholarshipController {
  UserSummaryResolver get _userSummaryResolver => _state.userSummaryResolver;
  ScholarshipRepository get _scholarshipRepository =>
      _state.scholarshipRepository;
  RxBool get isLoading => _state.isLoading;
  RxList<Map<String, dynamic>> get myScholarships => _state.myScholarships;
}
