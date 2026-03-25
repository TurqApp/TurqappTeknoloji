import 'package:turqappv2/Core/app_snackbar.dart';
import 'package:turqappv2/Core/Repositories/user_repository.dart';
import 'package:turqappv2/Core/Services/user_summary_resolver.dart';
import 'package:turqappv2/Core/Services/user_schema_fields.dart';
import 'package:get/get.dart';

part 'scholarship_applications_content_controller_data_part.dart';
part 'scholarship_applications_content_controller_fields_part.dart';

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
