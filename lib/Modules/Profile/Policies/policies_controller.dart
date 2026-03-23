import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/config_repository.dart';

part 'policies_controller_data_part.dart';
part 'policies_controller_navigation_part.dart';

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
