import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:turqappv2/Core/Repositories/test_repository.dart';
import 'package:turqappv2/Core/Services/silent_refresh_gate.dart';
import 'package:turqappv2/Models/Education/tests_model.dart';

class SearchTestsController extends GetxController {
  final TestRepository _testRepository = TestRepository.ensure();
  static const Duration _silentRefreshInterval = Duration(minutes: 5);
  final list = <TestsModel>[].obs;
  final filteredList = <TestsModel>[].obs;
  final isLoading = true.obs;
  final searchController = TextEditingController();
  final focusNode = FocusNode();

  @override
  void onInit() {
    super.onInit();
    unawaited(_bootstrapData());
    Future.delayed(const Duration(milliseconds: 100), () {
      Get.focusScope?.requestFocus(focusNode);
    });
  }

  @override
  void onClose() {
    searchController.dispose();
    focusNode.dispose();
    super.onClose();
  }

  Future<void> _bootstrapData() async {
    final cached = await _testRepository.fetchAll(cacheOnly: true);
    if (cached.isNotEmpty) {
      list.assignAll(cached);
      filteredList.assignAll(cached);
      isLoading.value = false;
      if (SilentRefreshGate.shouldRefresh(
        'tests:search_all',
        minInterval: _silentRefreshInterval,
      )) {
        unawaited(getData(silent: true, forceRefresh: true));
      }
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
    final items = await _testRepository.fetchAll(
      preferCache: !forceRefresh,
      forceRefresh: forceRefresh,
    );
    list.assignAll(items);
    filterSearchResults(searchController.text);
    SilentRefreshGate.markRefreshed('tests:search_all');
    isLoading.value = false;
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      filteredList.assignAll(list);
    } else {
      filteredList.assignAll(
        list.where(
          (test) =>
              test.aciklama.toLowerCase().contains(query.toLowerCase()) ||
              test.testTuru.toLowerCase().contains(query.toLowerCase()) ||
              test.dersler.any(
                (ders) => ders.toLowerCase().contains(query.toLowerCase()),
              ),
        ),
      );
    }
  }
}
