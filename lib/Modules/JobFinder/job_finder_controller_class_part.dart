part of 'job_finder_controller.dart';

class JobFinderController extends GetxController {
  static JobFinderController ensure({bool permanent = false}) {
    final existing = maybeFind();
    if (existing != null) return existing;
    return Get.put(JobFinderController(), permanent: permanent);
  }

  static JobFinderController? maybeFind() {
    final isRegistered = Get.isRegistered<JobFinderController>();
    if (!isRegistered) return null;
    return Get.find<JobFinderController>();
  }

  static const int _fullBootstrapLimit = ReadBudgetRegistry.jobHomeInitialLimit;
  static const String _listingSelectionPrefKeyPrefix =
      'pasaj_job_listing_selection';
  static const String _allTurkeyRaw = 'Tüm Türkiye';
  final _state = _JobFinderControllerState();

  @override
  void onInit() {
    super.onInit();
    _handleOnInit();
  }

  @override
  void onClose() {
    _handleOnClose();
    super.onClose();
  }
}
