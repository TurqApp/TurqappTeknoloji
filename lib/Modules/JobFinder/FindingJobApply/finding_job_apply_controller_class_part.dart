part of 'finding_job_apply_controller.dart';

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
  final cvVar = false.obs;
  final isFinding = false.obs;

  @override
  void onInit() {
    super.onInit();
    cvCheck();
  }

  Future<void> cvCheck() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty) return;
    try {
      final data = await _cvRepository.getCv(uid, preferCache: true);
      cvVar.value = data != null;
      if (data != null) {
        isFinding.value = data['findingJob'] ?? false;
      }
    } catch (_) {}
  }

  Future<void> toggleFindingJob() async {
    final uid = CurrentUserService.instance.effectiveUserId;
    if (uid.isEmpty || !cvVar.value) return;
    final next = !isFinding.value;
    isFinding.value = next;
    await _cvRepository.updateCvFields(uid, {'findingJob': next});
  }
}
