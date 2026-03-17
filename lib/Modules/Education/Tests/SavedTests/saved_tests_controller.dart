import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class SavedTestsController extends GetxController {
  final TestRepository _testRepository = TestRepository.ensure();
  final list = <TestsModel>[].obs;
  final isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final cached = await _testRepository.fetchFavorites(
      FirebaseAuth.instance.currentUser!.uid,
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
      final items = await _testRepository.fetchFavorites(
        FirebaseAuth.instance.currentUser!.uid,
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
