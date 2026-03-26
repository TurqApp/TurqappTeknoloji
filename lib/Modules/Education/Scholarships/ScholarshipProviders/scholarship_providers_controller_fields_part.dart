part of 'scholarship_providers_controller.dart';

class _ScholarshipProvidersControllerState {
  final UserRepository userRepository = UserRepository.ensure();
  final ScholarshipRepository scholarshipRepository =
      ensureScholarshipRepository();
  final RxBool isLoading = true.obs;
  final RxList<Map<String, dynamic>> providers = <Map<String, dynamic>>[].obs;
}

const Duration _scholarshipProvidersSilentRefreshInterval =
    Duration(minutes: 5);

extension ScholarshipProvidersControllerFieldsPart
    on ScholarshipProvidersController {
  UserRepository get _userRepository => _state.userRepository;
  ScholarshipRepository get _scholarshipRepository =>
      _state.scholarshipRepository;
  RxBool get isLoading => _state.isLoading;
  RxList<Map<String, dynamic>> get providers => _state.providers;
}
