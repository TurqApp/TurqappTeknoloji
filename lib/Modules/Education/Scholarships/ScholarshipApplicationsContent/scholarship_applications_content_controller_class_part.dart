part of 'scholarship_applications_content_controller.dart';

class ScholarshipApplicationsContentController extends GetxController {
  static ScholarshipApplicationsContentController ensure({
    required String tag,
    required String userID,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      ScholarshipApplicationsContentController(userID: userID),
      tag: tag,
      permanent: permanent,
    );
  }

  static ScholarshipApplicationsContentController? maybeFind({
    required String tag,
  }) {
    final isRegistered =
        Get.isRegistered<ScholarshipApplicationsContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<ScholarshipApplicationsContentController>(tag: tag);
  }

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
