import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Services/current_user_service.dart';

part 'test_past_result_content_controller_data_part.dart';
part 'test_past_result_content_controller_snapshot_part.dart';

class TestPastResultContentController extends GetxController {
  static TestPastResultContentController ensure(
    TestsModel model, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TestPastResultContentController(model),
      tag: tag,
      permanent: permanent,
    );
  }

  static TestPastResultContentController? maybeFind({String? tag}) {
    final isRegistered =
        Get.isRegistered<TestPastResultContentController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TestPastResultContentController>(tag: tag);
  }

  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final TestsModel model;
  final count = 0.obs;
  final isLoading = true.obs;
  final timeStamp = 0.obs;
  final TestRepository _testRepository = TestRepository.ensure();

  TestPastResultContentController(this.model);

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }
}
