import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'saved_tests_controller_runtime_part.dart';

class SavedTestsController extends GetxController {
  static SavedTestsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      SavedTestsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static SavedTestsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<SavedTestsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<SavedTestsController>(tag: tag);
  }

  final TestRepository _testRepository = TestRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    handleRuntimeInit();
  }
}
