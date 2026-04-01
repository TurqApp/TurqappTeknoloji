part of 'scholarship_providers_controller.dart';

class ScholarshipProvidersController extends GetxController {
  final _ScholarshipProvidersControllerState _state =
      _ScholarshipProvidersControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleInit();
  }
}

class _ScholarshipProvidersControllerState {
  final UserRepository userRepository = UserRepository.ensure();
  final ScholarshipSnapshotRepository scholarshipSnapshotRepository =
      ensureScholarshipSnapshotRepository();
  final RxBool isLoading = true.obs;
  final RxList<Map<String, dynamic>> providers = <Map<String, dynamic>>[].obs;
}

const Duration _scholarshipProvidersSilentRefreshInterval =
    Duration(minutes: 5);

extension ScholarshipProvidersControllerFieldsPart
    on ScholarshipProvidersController {
  UserRepository get _userRepository => _state.userRepository;
  ScholarshipSnapshotRepository get _scholarshipSnapshotRepository =>
      _state.scholarshipSnapshotRepository;
  RxBool get isLoading => _state.isLoading;
  RxList<Map<String, dynamic>> get providers => _state.providers;
}
