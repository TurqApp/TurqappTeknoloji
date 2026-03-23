import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'finding_job_apply_controller_data_part.dart';
part 'finding_job_apply_controller_actions_part.dart';

class FindingJobApplyController extends GetxController {
  static FindingJobApplyController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      FindingJobApplyController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static FindingJobApplyController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<FindingJobApplyController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<FindingJobApplyController>(tag: tag);
  }

  final CvRepository _cvRepository = CvRepository.ensure();
  var cvVar = false.obs;
  var isFinding = false.obs;
  @override
  void onInit() {
    super.onInit();
    cvCheck();
  }
}
