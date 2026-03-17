import 'dart:async';

import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class LessonBasedTestsController extends GetxController {
  final TestRepository _testRepository = TestRepository.ensure();
  final String testTuru;
  final list = <TestsModel>[].obs;
  final isLoading = false.obs;

  LessonBasedTestsController(this.testTuru);

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final cached = await _testRepository.fetchByType(
      testTuru,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      await getData(silent: true, forceRefresh: true);
      return;
    }
    await getData();
  }

  Future<void> getData({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final items = await _testRepository.fetchByType(
        testTuru,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      list.assignAll(items);
    } finally {
      isLoading.value = false;
    }
  }
}
