part of 'policies_controller.dart';

class PoliciesController extends GetxController {
  static PoliciesController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      PoliciesController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static PoliciesController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<PoliciesController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<PoliciesController>(tag: tag);
  }

  var privacyPolicy = "".obs;
  var eula = "".obs;
  var ad = "".obs;

  var selection = 0.obs;
  PageController pageController = PageController(initialPage: 0);

  Future<void> _loadPolicies() async {
    final doc = await ConfigRepository.ensure().getLegacyConfigDoc(
      collection: 'Yönetim',
      docId: 'Policies',
      preferCache: true,
    );
    if (doc == null) return;
    privacyPolicy.value = (doc["privacy"] ?? "").toString();
    eula.value = (doc["eula"] ?? "").toString();
    ad.value = (doc["ad"] ?? "").toString();
  }

  @override
  void onInit() {
    super.onInit();
    _loadPolicies();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
