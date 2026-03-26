part of 'scholarship_applications_content_controller.dart';

class ScholarshipApplicationsContentController extends GetxController {
  final String userID;
  final UserRepository _userRepository = UserRepository.ensure();
  final UserSummaryResolver _userSummaryResolver = UserSummaryResolver.ensure();
  final _state = _ScholarshipApplicationsContentControllerState();

  ScholarshipApplicationsContentController({required this.userID});

  @override
  void onInit() {
    super.onInit();
    _ScholarshipApplicationsContentControllerDataPart(this).handleOnInit();
  }
}
