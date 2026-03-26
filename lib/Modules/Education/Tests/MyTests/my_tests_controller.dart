import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'my_tests_controller_runtime_part.dart';

class MyTestsController extends GetxController {
  static MyTestsController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      MyTestsController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static MyTestsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<MyTestsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<MyTestsController>(tag: tag);
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
