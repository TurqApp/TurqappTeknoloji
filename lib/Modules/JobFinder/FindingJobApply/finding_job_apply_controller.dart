import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/cv_repository.dart';
import 'package:turqappv2/Services/current_user_service.dart';

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
    if (!Get.isRegistered<FindingJobApplyController>(tag: tag)) return null;
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

  Future<void> cvCheck() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty) return;
    try {
      final data = await _cvRepository.getCv(uid, preferCache: true);
      cvVar.value = data != null;
      if (data != null) {
        isFinding.value = data["findingJob"] ?? false;
      }
    } catch (_) {}
  }

  Future<void> toggleFindingJob() async {
    final uid = CurrentUserService.instance.userId;
    if (uid.isEmpty || !cvVar.value) return;
    final next = !isFinding.value;
    isFinding.value = next;
    await _cvRepository.updateCvFields(uid, {"findingJob": next});
  }
}
