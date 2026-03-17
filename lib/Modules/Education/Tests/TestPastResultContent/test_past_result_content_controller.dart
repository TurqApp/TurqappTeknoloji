import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class TestPastResultContentController extends GetxController {
  final TestsModel model;
  final count = 0.obs;
  final isLoading = true.obs;
  final timeStamp = 0.obs;
  final TestRepository _testRepository = TestRepository.ensure();

  TestPastResultContentController(this.model);

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
  }

  Future<void> _bootstrapData() async {
    final cached = await _testRepository.fetchAnswers(
      model.docID,
      cacheOnly: true,
    );
    if (cached.isNotEmpty) {
      _applySnapshot(cached);
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
    if (!silent) {
      isLoading.value = true;
    }
    try {
      final snapshot = await _testRepository.fetchAnswers(
        model.docID,
        preferCache: !forceRefresh,
        forceRefresh: forceRefresh,
      );
      _applySnapshot(snapshot);
    } catch (_) {
    } finally {
      isLoading.value = false;
    }
  }

  void _applySnapshot(List<Map<String, dynamic>> snapshot) {
    count.value = 0;
    timeStamp.value = 0;
    final filtered = snapshot
        .where(
          (doc) =>
              (doc["userID"] ?? "").toString() ==
              FirebaseAuth.instance.currentUser!.uid,
        )
        .toList(growable: false)
      ..sort(
        (a, b) =>
            ((b["timeStamp"] ?? 0) as num).compareTo((a["timeStamp"] ?? 0) as num),
      );

    if (filtered.isNotEmpty) {
      count.value = filtered.length;
      timeStamp.value = ((filtered.first["timeStamp"] ?? 0) as num).toInt();
    }
  }
}
