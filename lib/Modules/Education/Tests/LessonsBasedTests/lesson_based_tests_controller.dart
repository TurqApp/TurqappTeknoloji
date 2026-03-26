import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

part 'lesson_based_tests_controller_runtime_part.dart';

class LessonBasedTestsController extends GetxController {
  static LessonBasedTestsController ensure(
    String testTuru, {
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      LessonBasedTestsController(testTuru),
      tag: tag,
      permanent: permanent,
    );
  }

  static LessonBasedTestsController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<LessonBasedTestsController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<LessonBasedTestsController>(tag: tag);
  }

  final TestRepository _testRepository = TestRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final String testTuru;
  final list = <TestsModel>[].obs;
  final isLoading = false.obs;

  LessonBasedTestsController(this.testTuru);

  @override
  void onInit() {
    super.onInit();
    handleRuntimeInit();
  }
}
