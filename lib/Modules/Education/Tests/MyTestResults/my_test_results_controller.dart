import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class MyTestResultsController extends GetxController {
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;
  final TestRepository _testRepository = TestRepository.ensure();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final currentUserID = FirebaseAuth.instance.currentUser!.uid;
    final cached = await _testRepository.fetchAnsweredByUser(
      currentUserID,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      isLoading.value = false;
      await findAndGetTestler(silent: true, forceRefresh: true);
      return;
    }
    await findAndGetTestler();
  }

  Future<void> findAndGetTestler({
    bool silent = false,
    bool forceRefresh = false,
  }) async {
    if (!silent || list.isEmpty) {
      isLoading.value = true;
    }
    try {
      final currentUserID = FirebaseAuth.instance.currentUser!.uid;
      final items = await _testRepository.fetchAnsweredByUser(
        currentUserID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      list.assignAll(items);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
