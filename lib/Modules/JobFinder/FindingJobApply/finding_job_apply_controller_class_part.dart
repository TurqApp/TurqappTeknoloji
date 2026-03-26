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

  final _FindingJobApplyControllerState _state =
      _FindingJobApplyControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleFindingJobApplyControllerInit(this);
  }

  Future<void> cvCheck() => _checkFindingJobCv(this);

  Future<void> toggleFindingJob() => _toggleFindingJobState(this);
}
