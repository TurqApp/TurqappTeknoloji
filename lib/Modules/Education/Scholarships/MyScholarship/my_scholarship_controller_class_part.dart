part of 'my_scholarship_controller.dart';

class MyScholarshipController extends GetxController {
  static MyScholarshipController ensure({
    required String tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(MyScholarshipController(), tag: tag, permanent: permanent);
  }

  static MyScholarshipController? maybeFind({required String tag}) {
    final isRegistered = Get.isRegistered<MyScholarshipController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyScholarshipController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final _MyScholarshipControllerState _state = _MyScholarshipControllerState();

  @override
  void onInit() {
    super.onInit();
    unawaited(bootstrapMyScholarships());
  }
}
