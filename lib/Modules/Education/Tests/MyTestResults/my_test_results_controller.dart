import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class MyTestResultsController extends GetxController {
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
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
      if (SilentRefreshGate.shouldRefresh(
        'tests:answered:$currentUserID',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(findAndGetTestler(silent: true, forceRefresh: true));
      }
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
      SilentRefreshGate.markRefreshed('tests:answered:$currentUserID');
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }
}
