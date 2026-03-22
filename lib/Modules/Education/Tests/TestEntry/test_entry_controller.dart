import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/functions.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';
import 'package:turqappv2/Modules/Education/Tests/CreateTest/create_test_controller.dart';
import 'package:turqappv2/Modules/Education/Tests/SolveTest/solve_test.dart';

part 'test_entry_controller_data_part.dart';
part 'test_entry_controller_actions_part.dart';

class TestEntryController extends GetxController {
  static TestEntryController ensure({
    String? tag,
    bool permanent = false,
  }) {
    final existing = maybeFind(tag: tag);
    if (existing != null) return existing;
    return Get.put(
      TestEntryController(),
      tag: tag,
      permanent: permanent,
    );
  }

  static TestEntryController? maybeFind({String? tag}) {
    final isRegistered = Get.isRegistered<TestEntryController>(tag: tag);
    if (!isRegistered) return null;
    return Get.find<TestEntryController>(tag: tag);
  }

  final textController = TextEditingController();
  final focusNode = FocusNode();
  final model = Rx<TestsModel?>(null);
  final isLoading = false.obs;
  final TestRepository _testRepository = TestRepository.ensure();
  final _helper = CreateTestController(null);

  @override
  void onInit() {
    super.onInit();
    _handleControllerInit();
  }

  @override
  void onClose() {
    _handleControllerClose();
    super.onClose();
  }
}
